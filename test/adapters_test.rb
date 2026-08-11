# frozen_string_literal: true

require_relative "test_helper"
require "json"
require "rexml/document"

class AdaptersTest < Minitest::Test
  def test_every_adapter_generates_every_selected_variant
    themes = Lacold.registry.themes

    Lacold::Adapters.all.each do |adapter|
      outputs = adapter.render(themes)
      assert outputs.any?, adapter.id
      themes.each do |theme|
        assert outputs.any? { |item| item.path.include?(theme.id) }, "#{adapter.id} omitted #{theme.id}"
      end
    end
  end

  def test_vscode_extension_declares_all_themes
    outputs = Lacold::Adapters.find("vscode").render(Lacold.registry.themes)
    package = JSON.parse(outputs.find { |item| item.path == "vscode/package.json" }.content)

    assert_equal 10, package.dig("contributes", "themes").size
    assert_equal %w[vs vs-dark], package.dig("contributes", "themes").map { |item| item.fetch("uiTheme") }.uniq.sort
  end

  def test_xml_formats_parse
    themes = Lacold.registry.themes(colors: ["blue"], modes: [:light])
    %w[iterm2 terminal-app bat codex xcode intellij gedit visual-studio].each do |target|
      Lacold::Adapters.find(target).render(themes).each do |item|
        next unless item.path.match?(/\.(?:itermcolors|terminal|tmTheme|xccolortheme|icls|xml|vstheme)\z/)

        assert REXML::Document.new(item.content), item.path
      end
    end
  end

  def test_all_json_theme_formats_parse
    themes = Lacold.registry.themes(colors: ["blue"], modes: [:dark])
    %w[coteditor kate opencode windows-terminal zed agy].each do |target|
      Lacold::Adapters.find(target).render(themes).each do |item|
        next unless item.path.end_with?(".json", ".cottheme", ".theme")

        assert JSON.parse(item.content), item.path
      end
    end
  end

  def test_vim_and_neovim_share_the_compatible_adapter
    assert_same Lacold::Adapters.find("vim"), Lacold::Adapters.find("neovim")
    content = Lacold::Adapters.find("vim").render(Lacold.registry.themes(colors: ["pink"], modes: [:dark])).first.content
    assert_includes content, "let g:colors_name = 'lacold-air-pink-dark'"
    assert_includes content, "set background=dark"
  end

  def test_monochrome_state_mapping_uses_only_the_authored_accent_and_neutrals
    theme = Lacold.registry.themes(colors: ["pink"], modes: [:light]).first
    content = Lacold::Adapters.find("vim").render([theme]).first.content
    allowed = (theme.palette.neutrals.values + theme.palette.accent.values).uniq
    generated = content.scan(/#[0-9A-F]{6}/)

    assert generated.all? { |color| allowed.include?(color) }
    refute_includes generated, "#AA4949"
    refute_includes generated, "#417553"
  end
end
