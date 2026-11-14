# frozen_string_literal: true

require_relative "test_helper"
require "json"
require "rexml/document"

class AdaptersTest < Minitest::Test
  PAIRED_ADAPTERS = %w[fish iterm2 opencode vim].freeze

  def test_every_adapter_generates_every_selected_variant
    themes = Lacold.themes

    Lacold::Adapters.all.each do |adapter|
      outputs = adapter.render(themes)
      assert outputs.any?, adapter.id
      if PAIRED_ADAPTERS.include?(adapter.id)
        themes.map(&:family_id).uniq.each do |family_id|
          assert outputs.any? { |item| item.path.include?(family_id) }, "#{adapter.id} omitted #{family_id}"
        end
      else
        themes.each do |theme|
          identifier = adapter.id == "coteditor" ? theme.name : theme.id
          assert outputs.any? { |item| item.path.include?(identifier) }, "#{adapter.id} omitted #{theme.id}"
        end
      end
    end
  end

  def test_every_adapter_includes_a_usage_readme
    root_readme = File.read(File.expand_path("../README.md", __dir__))

    Lacold::Adapters.all.each do |adapter|
      readme = adapter.render(Lacold.themes).find do |item|
        item.path == "#{adapter.id}/README.md"
      end
      source = File.read(File.expand_path("../targets/#{adapter.id}/README.md", __dir__))

      assert readme, "#{adapter.id} omitted README.md"
      assert_match(/^# Lacold /, readme.content, adapter.id)
      assert_equal source, readme.content, "#{adapter.id} README differs from its source"
      assert_includes root_readme, "(targets/#{adapter.id}/README.md)", adapter.id
    end
  end

  def test_vscode_extension_declares_all_themes
    outputs = Lacold::Adapters.find("vscode").render(Lacold.themes)
    package = JSON.parse(outputs.find { |item| item.path == "vscode/package.json" }.content)

    assert_equal 12, package.dig("contributes", "themes").size
    assert_equal %w[vs vs-dark], package.dig("contributes", "themes").map { |item| item.fetch("uiTheme") }.uniq.sort
    assert_equal "aozy", package.fetch("publisher")
    assert_equal "images/lacold-wordmark-logo.png", package.fetch("icon")
    assert_equal "SEE LICENSE IN LICENSE.txt", package.fetch("license")
    assert_equal "https://github.com/ecnelises/lacold-theme.git", package.dig("repository", "url")
    assert_equal "https://github.com/ecnelises/lacold-theme/issues", package.dig("bugs", "url")
    assert_equal ["themes/**", "images/**", "README.md", "CHANGELOG.md", "LICENSE.txt"], package.fetch("files")
    assert outputs.any? { |item| item.path == "vscode/CHANGELOG.md" }

    icon = outputs.find { |item| item.path == "vscode/images/lacold-wordmark-logo.png" }
    assert icon
    assert_equal File.binread(File.expand_path("../assets/lacold-wordmark-logo.png", __dir__)), icon.content
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

  def test_rainbow_vscode_colors_structure_and_literals_but_keeps_variables_neutral
    theme = Lacold.themes(colors: ["rainbow"], modes: [:dark]).first
    output = Lacold::Adapters.find("vscode").render([theme])
      .find { |item| item.path.end_with?("-color-theme.json") }
    generated = JSON.parse(output.content)
    semantic = generated.fetch("semanticTokenColors")

    assert_equal theme.syntax.fetch(:keyword), semantic.fetch("keyword")
    assert_equal theme.syntax.fetch(:type), semantic.fetch("type")
    assert_equal theme.syntax.fetch(:constant), semantic.fetch("enumMember")
    assert_equal theme.syntax.fetch(:number), semantic.fetch("number")
    assert_equal theme.syntax.fetch(:decorator), semantic.fetch("decorator")
    assert_equal theme.syntax.fetch(:string), semantic.fetch("string")
    assert_equal theme.syntax.fetch(:function), semantic.fetch("function")
    assert_equal theme.syntax.fetch(:property), semantic.fetch("property")
    assert_equal theme.fg, semantic.fetch("variable")
    assert_equal theme.secondary, semantic.fetch("operator")
    assert_equal theme.primary, generated.dig("colors", "editorCursor.foreground")
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

  def test_visual_studio_colors_follow_compiler_element_order
    theme = Lacold.themes(colors: ["blue"], modes: [:dark]).first
    output = Lacold::Adapters.find("visual-studio").render([theme])
      .find { |item| item.path.end_with?(".vstheme") }
    document = REXML::Document.new(output.content)

    REXML::XPath.each(document, "//Color") do |color|
      children = color.elements.to_a.map(&:name)
      assert_equal %w[Background Foreground].select { |name| children.include?(name) }, children, color.attributes["Name"]
    end
  end

  def test_visual_studio_cpp_classifications_use_theme_colors
    theme = Lacold.themes(colors: ["rainbow"], modes: [:dark]).first
    output = Lacold::Adapters.find("visual-studio").render([theme])
      .find { |item| item.path.end_with?(".vstheme") }
    document = REXML::Document.new(output.content)
    category = REXML::XPath.first(document, "//Category[@GUID='#{Lacold::Adapters::VisualStudio::CLASSIFICATION_CATEGORY}']")

    assert category
    expected = {
      "Keyword" => theme.syntax_color(:keyword, theme.primary),
      "keyword - control" => theme.syntax_color(:keyword, theme.primary),
      "CppControlKeywordSyntacticTokenFormat" => theme.syntax_color(:keyword, theme.primary),
      "Preprocessor Keyword" => theme.syntax_color(:preprocessor, theme.primary),
      "preprocessor text" => theme.fg,
      "CppMacroSemanticTokenFormat" => theme.syntax_color(:macro, theme.accent_secondary)
    }
    expected.each do |name, color|
      item = category.elements.to_a.find { |element| element.attributes["Name"] == name }
      assert item, name
      assert_equal "FF#{color.delete_prefix('#').upcase}", item.elements["Foreground"].attributes["Source"], name
    end
  end

  def test_codex_generates_installable_theme_and_config
    theme = Lacold.themes(colors: ["blue"], modes: [:dark]).first
    outputs = Lacold::Adapters.find("codex").render([theme])
    theme_output = outputs.find { |item| item.path == "codex/themes/#{theme.id}.tmTheme" }
    config_output = outputs.find { |item| item.path == "codex/config/#{theme.id}.toml" }

    assert theme_output
    assert config_output
    document = REXML::Document.new(theme_output.content)
    assert_equal theme.name, REXML::XPath.first(document, "/plist/dict/key[.='name']/following-sibling::string[1]").text
    assert_includes theme_output.content, theme.bg
    assert_includes theme_output.content, theme.caret
    assert_includes config_output.content, "[tui]"
    assert_includes config_output.content, %(theme = "#{theme.id}")
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
    assert_includes content, "let g:colors_name = 'lacold-pink-dark'"
    assert_includes content, "set background=dark"
  end

  def test_complete_vim_family_follows_background
    themes = Lacold.themes(colors: ["blue"])
    output = Lacold::Adapters.find("vim").render(themes)
      .find { |item| item.path == "vim/colors/lacold-blue.vim" }

    assert output
    assert_includes output.content, "if &background ==# 'light'"
    assert_includes output.content, "let g:colors_name = 'lacold-blue'"
    assert_includes output.content, themes.find { |theme| theme.mode == :light }.bg
    assert_includes output.content, themes.find { |theme| theme.mode == :dark }.bg
    refute_match(/^set background=/, output.content)
  end

  def test_opencode_combines_authored_light_and_dark_values
    themes = Lacold.themes(colors: ["blue"])
    generated = JSON.parse(Lacold::Adapters.find("opencode").render(themes)
      .find { |item| item.path == "opencode/lacold-blue.json" }.content)
    light = themes.find { |theme| theme.mode == :light }
    dark = themes.find { |theme| theme.mode == :dark }

    assert_equal dark.bg, generated.dig("defs", "dark_background")
    assert_equal light.bg, generated.dig("defs", "light_background")
    assert_equal "dark_background", generated.dig("theme", "background", "dark")
    assert_equal "light_background", generated.dig("theme", "background", "light")
  end

  def test_iterm2_combines_light_and_dark_profile_colors
    content = Lacold::Adapters.find("iterm2").render(Lacold.themes(colors: ["blue"]))
      .find { |item| item.path == "iterm2/lacold-blue.itermcolors" }.content

    assert REXML::Document.new(content)
    assert_includes content, "<key>Background Color (Dark)</key>"
    assert_includes content, "<key>Background Color (Light)</key>"
    assert_includes content, "<key>Use Separate Colors for Light and Dark Mode</key>"
  end

  def test_kitty_generates_os_appearance_files
    outputs = Lacold::Adapters.find("kitty").render(Lacold.themes(colors: ["blue"]))
    paths = outputs.map(&:path)

    assert_includes paths, "kitty/auto/lacold-blue/dark-theme.auto.conf"
    assert_includes paths, "kitty/auto/lacold-blue/light-theme.auto.conf"
    assert_includes paths, "kitty/auto/lacold-blue/no-preference-theme.auto.conf"
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

  def test_fish_generates_native_adaptive_theme_files
    themes = Lacold.themes(colors: ["blue"])
    outputs = Lacold::Adapters.find("fish").render(themes)
    fish = outputs.find { |item| item.path == "fish/themes/lacold-blue.theme" }
    light = themes.find { |theme| theme.mode == :light }
    dark = themes.find { |theme| theme.mode == :dark }

    assert fish
    assert_includes fish.content, "# name: 'Lacold Blue'"
    assert_includes fish.content, "[light]\n# preferred_background: #{light.bg.delete_prefix("#")}"
    assert_includes fish.content, "[dark]\n# preferred_background: #{dark.bg.delete_prefix("#")}"
    assert_includes fish.content, "[unknown]\n# preferred_background: #{dark.bg.delete_prefix("#")}"
    assert_includes fish.content, "fish_color_error AA4949"
    assert_includes fish.content, "fish_color_quote 417553"
    assert_match(/^fish_pager_color_selected_background --background=[0-9A-F]{6}$/, fish.content)
    refute_includes fish.content, "set -g"
  end

  def test_coteditor_generates_named_native_themes_with_authored_colors
    theme = Lacold.themes(colors: ["rainbow"], modes: [:dark]).first
    output = Lacold::Adapters.find("coteditor").render([theme])
      .find { |item| item.path == "coteditor/#{theme.name}.cottheme" }

    assert output
    generated = JSON.parse(output.content)
    assert_equal theme.name, generated.fetch("name")
    assert_equal theme.bg, generated.dig("background", "color")
    assert_equal theme.primary, generated.dig("insertionPoint", "color")
    assert_equal false, generated.dig("insertionPoint", "usesSystemSetting")
    assert_equal theme.selection, generated.dig("selection", "color")
    assert_equal false, generated.dig("selection", "usesSystemSetting")
    assert_equal theme.syntax.fetch(:function), generated.dig("commands", "color")
    assert_equal theme.syntax.fetch(:constant), generated.dig("characters", "color")
    assert_equal theme.syntax.fetch(:constant), generated.dig("values", "color")
    assert_equal theme.syntax.fetch(:variable), generated.dig("variables", "color")
    assert_equal "https://github.com/ecnelises/lacold-theme", generated.dig("metadata", "distributionURL")
  end

  def test_fish_keeps_filtered_variants_as_selectable_single_mode_themes
    theme = Lacold.themes(colors: ["blue"], modes: [:dark]).first
    outputs = Lacold::Adapters.find("fish").render([theme])
    fish = outputs.find { |item| item.path == "fish/themes/#{theme.id}.theme" }

    assert fish
    assert_includes fish.content, "# name: '#{theme.name}'"
    assert_includes fish.content, "# preferred_background: #{theme.bg.delete_prefix("#")}"
    refute_match(/^\[(?:light|dark|unknown)\]$/, fish.content)
    refute_includes fish.content, "set -g"
  end

  def test_fish_and_kitty_share_editor_semantics
    theme = Lacold.themes(colors: ["blue"], modes: [:light]).first
    fish = Lacold::Adapters.find("fish").render([theme]).first.content
    kitty = Lacold::Adapters.find("kitty").render([theme]).first.content

    assert_includes fish, "fish_color_error AA4949"
    assert_includes fish, "fish_color_quote 417553"
    assert_includes kitty, "cursor #{theme.caret}"
    assert_includes kitty, "bell_border_color #9D5419"
    assert_includes kitty, "color1 #AA4949"
    assert_includes kitty, "color2 #417553"
  end
end
