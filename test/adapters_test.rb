# frozen_string_literal: true

require_relative "test_helper"
require "json"
require "rexml/document"

class AdaptersTest < Minitest::Test
  def test_every_adapter_generates_every_selected_variant
    themes = Lacold.themes

    Lacold::Adapters.all.each do |adapter|
      outputs = adapter.render(themes)
      assert outputs.any?, adapter.id
      themes.each do |theme|
        assert outputs.any? { |item| item.path.include?(theme.id) }, "#{adapter.id} omitted #{theme.id}"
      end
    end
  end

  def test_vscode_extension_declares_all_themes
    outputs = Lacold::Adapters.find("vscode").render(Lacold.themes)
    package = JSON.parse(outputs.find { |item| item.path == "vscode/package.json" }.content)

    assert_equal 10, package.dig("contributes", "themes").size
    assert_equal %w[vs vs-dark], package.dig("contributes", "themes").map { |item| item.fetch("uiTheme") }.uniq.sort
  end

  def test_vscode_preserves_editor_ui_and_semantic_feedback
    theme = Lacold.themes(colors: ["blue"], modes: [:light]).first
    output = Lacold::Adapters.find("vscode").render([theme])
      .find { |item| item.path.end_with?("-color-theme.json") }
    generated = JSON.parse(output.content)
    colors = generated.fetch("colors")
    semantic = generated.fetch("semanticTokenColors")

    %w[
      activityBar.activeBackground editor.findRangeHighlightBackground
      editorBracketHighlight.foreground6 editorHoverWidget.background
      editorOverviewRuler.errorForeground editorSuggestWidget.foreground
      minimap.findMatchHighlight statusBar.noFolderBackground
      terminalCursor.foreground terminal.selectionBackground
    ].each { |key| assert colors.key?(key), key }
    assert_equal theme.caret, colors.fetch("editorCursor.foreground")
    assert_equal theme.red, colors.fetch("editorError.foreground")
    assert_equal theme.orange, colors.fetch("editorWarning.foreground")
    assert_equal theme.green, colors.fetch("editorHint.foreground")
    assert_equal theme.green, colors.fetch("gitDecoration.addedResourceForeground")
    assert_equal theme.fg, semantic.fetch("function")
    assert_equal theme.fg, semantic.fetch("regexp")
  end

  def test_xml_formats_parse
    themes = Lacold.themes(colors: ["blue"], modes: [:light])
    %w[iterm2 terminal-app bat codex xcode intellij gedit visual-studio].each do |target|
      Lacold::Adapters.find(target).render(themes).each do |item|
        next unless item.path.match?(/\.(?:itermcolors|terminal|tmTheme|xccolortheme|icls|xml|vstheme)\z/)

        assert REXML::Document.new(item.content), item.path
      end
    end
  end

  def test_all_json_theme_formats_parse
    themes = Lacold.themes(colors: ["blue"], modes: [:dark])
    %w[coteditor kate opencode windows-terminal zed agy].each do |target|
      Lacold::Adapters.find(target).render(themes).each do |item|
        next unless item.path.end_with?(".json", ".cottheme", ".theme")

        assert JSON.parse(item.content), item.path
      end
    end
  end

  def test_vim_and_neovim_share_the_compatible_adapter
    assert_same Lacold::Adapters.find("vim"), Lacold::Adapters.find("neovim")
    content = Lacold::Adapters.find("vim").render(Lacold.themes(colors: ["pink"], modes: [:dark])).first.content
    assert_includes content, "let g:colors_name = 'lacold-air-pink-dark'"
    assert_includes content, "set background=dark"
  end

  def test_generated_vim_theme_uses_authored_palette_roles
    theme = Lacold.themes(colors: ["pink"], modes: [:light]).first
    content = Lacold::Adapters.find("vim").render([theme]).first.content
    allowed = theme.colors.values.uniq
    generated = content.scan(/#[0-9A-F]{6}/)

    assert generated.all? { |color| allowed.include?(color) }
    assert_includes generated, theme.red
    assert_includes generated, theme.green
  end

  def test_fish_and_kitty_share_editor_semantics
    theme = Lacold.themes(colors: ["blue"], modes: [:light]).first
    fish = Lacold::Adapters.find("fish").render([theme]).first.content
    kitty = Lacold::Adapters.find("kitty").render([theme]).first.content

    assert_includes fish, "set -g fish_color_error AA4949"
    assert_includes fish, "set -g fish_color_quote 417553"
    assert_includes kitty, "cursor #03C0FF"
    assert_includes kitty, "bell_border_color #9D5419"
    assert_includes kitty, "color1 #AA4949"
    assert_includes kitty, "color2 #417553"
  end
end
