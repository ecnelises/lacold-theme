# frozen_string_literal: true

module Lacold
  module Adapters
    class VSCode < Base
      def id = "vscode"
      def name = "Visual Studio Code"
      def description = "A VS Code extension containing every selected Light/Dark variant"

      def render(themes)
        files = themes.map do |theme|
          output("vscode/themes/#{theme.id}-color-theme.json", json(vscode_theme(theme)))
        end
        files.concat([
          output("vscode/package.json", json(package(themes))),
          output("vscode/README.md", vscode_readme(themes)),
          output("vscode/LICENSE.txt", File.read(File.expand_path("../../../LICENSE", __dir__)))
        ])
      end

      private

      def package(themes)
        {
          "name" => "lacold-theme",
          "displayName" => "Lacold Theme",
          "description" => "Restrained monochrome themes generated from the Lacold palette.",
          "version" => Lacold::VERSION,
          "publisher" => "ecnelises",
          "license" => "MIT",
          "engines" => {"vscode" => "^1.75.0"},
          "categories" => ["Themes"],
          "keywords" => %w[theme light dark minimal monochrome],
          "contributes" => {
            "themes" => themes.map do |theme|
              {
                "label" => theme.name,
                "uiTheme" => theme.dark? ? "vs-dark" : "vs",
                "path" => "./themes/#{theme.id}-color-theme.json"
              }
            end
          }
        }
      end

      def vscode_theme(theme)
        {
          "$schema" => "vscode://schemas/color-theme",
          "name" => theme.name,
          "type" => theme.mode.to_s,
          "semanticHighlighting" => true,
          "colors" => workbench_colors(theme),
          "tokenColors" => theme.textmate_settings.map do |name, scopes, foreground, style|
            settings = {"foreground" => foreground}
            settings["fontStyle"] = style if style
            {"name" => name, "scope" => scopes, "settings" => settings}
          end,
          "semanticTokenColors" => semantic_colors(theme)
        }
      end

      def workbench_colors(theme)
        {
          "focusBorder" => "#{theme.primary}80",
          "foreground" => theme.fg,
          "descriptionForeground" => theme.secondary,
          "disabledForeground" => theme.faint,
          "errorForeground" => theme.strong,
          "icon.foreground" => theme.secondary,
          "selection.background" => theme.selection,
          "textLink.foreground" => theme.primary,
          "textLink.activeForeground" => theme.accent_secondary,
          "textBlockQuote.background" => theme.surface,
          "textBlockQuote.border" => theme.accent_faint,
          "textCodeBlock.background" => theme.surface,
          "button.background" => theme.primary,
          "button.foreground" => theme.bg,
          "button.hoverBackground" => theme.strong,
          "button.secondaryBackground" => theme.raised,
          "button.secondaryForeground" => theme.fg,
          "button.secondaryHoverBackground" => theme.border,
          "dropdown.background" => theme.bg,
          "dropdown.border" => theme.border,
          "dropdown.foreground" => theme.fg,
          "input.background" => theme.bg,
          "input.border" => theme.border,
          "input.foreground" => theme.fg,
          "input.placeholderForeground" => theme.muted,
          "inputOption.activeBackground" => theme.selection,
          "inputOption.activeBorder" => theme.primary,
          "inputValidation.errorBackground" => theme.wash,
          "inputValidation.errorBorder" => theme.strong,
          "inputValidation.warningBackground" => theme.wash,
          "inputValidation.warningBorder" => theme.primary,
          "inputValidation.infoBackground" => theme.wash,
          "inputValidation.infoBorder" => theme.accent_secondary,
          "badge.background" => theme.selection,
          "badge.foreground" => theme.fg,
          "progressBar.background" => theme.primary,
          "list.activeSelectionBackground" => theme.selection,
          "list.activeSelectionForeground" => theme.fg,
          "list.inactiveSelectionBackground" => theme.inactive_selection,
          "list.hoverBackground" => theme.surface,
          "list.focusOutline" => "#{theme.primary}80",
          "list.highlightForeground" => theme.primary,
          "list.errorForeground" => theme.strong,
          "list.warningForeground" => theme.primary,
          "activityBar.background" => theme.surface,
          "activityBar.foreground" => theme.fg,
          "activityBar.inactiveForeground" => theme.muted,
          "activityBar.border" => theme.border,
          "activityBar.activeBorder" => theme.primary,
          "activityBarBadge.background" => theme.primary,
          "activityBarBadge.foreground" => theme.bg,
          "sideBar.background" => theme.surface,
          "sideBar.foreground" => theme.secondary,
          "sideBar.border" => theme.border,
          "sideBarTitle.foreground" => theme.fg,
          "sideBarSectionHeader.background" => theme.raised,
          "sideBarSectionHeader.foreground" => theme.secondary,
          "sideBarSectionHeader.border" => theme.border,
          "editorGroupHeader.tabsBackground" => theme.surface,
          "editorGroupHeader.tabsBorder" => theme.border,
          "editorGroup.border" => theme.border,
          "tab.activeBackground" => theme.bg,
          "tab.activeForeground" => theme.fg,
          "tab.activeBorderTop" => theme.primary,
          "tab.inactiveBackground" => theme.surface,
          "tab.inactiveForeground" => theme.muted,
          "tab.border" => theme.border,
          "editor.background" => theme.bg,
          "editor.foreground" => theme.fg,
          "editorLineNumber.foreground" => theme.line_nr,
          "editorLineNumber.activeForeground" => theme.line_nr_active,
          "editorCursor.foreground" => theme.primary,
          "editor.selectionBackground" => theme.selection,
          "editor.inactiveSelectionBackground" => theme.inactive_selection,
          "editor.selectionHighlightBackground" => "#{theme.wash}B3",
          "editor.wordHighlightBackground" => "#{theme.wash}B3",
          "editor.wordHighlightStrongBackground" => theme.selection,
          "editor.findMatchBackground" => theme.selection,
          "editor.findMatchBorder" => theme.strong,
          "editor.findMatchHighlightBackground" => "#{theme.wash}B3",
          "editor.hoverHighlightBackground" => theme.wash,
          "editor.lineHighlightBackground" => theme.line,
          "editorWhitespace.foreground" => theme.whitespace,
          "editorIndentGuide.background1" => theme.border,
          "editorIndentGuide.activeBackground1" => theme.accent_faint,
          "editorRuler.foreground" => theme.border,
          "editorBracketMatch.background" => theme.bracket,
          "editorBracketMatch.border" => theme.accent_faint,
          "editorGutter.background" => theme.bg,
          "editorGutter.addedBackground" => theme.accent_secondary,
          "editorGutter.modifiedBackground" => theme.primary,
          "editorGutter.deletedBackground" => theme.strong,
          "editorError.foreground" => theme.strong,
          "editorError.background" => "#{theme.wash}66",
          "editorWarning.foreground" => theme.primary,
          "editorWarning.background" => "#{theme.wash}55",
          "editorInfo.foreground" => theme.accent_secondary,
          "editorInfo.background" => "#{theme.wash}44",
          "editorHint.foreground" => theme.accent_faint,
          "editorWidget.background" => theme.surface,
          "editorWidget.foreground" => theme.fg,
          "editorWidget.border" => theme.border,
          "editorSuggestWidget.background" => theme.surface,
          "editorSuggestWidget.border" => theme.border,
          "editorSuggestWidget.highlightForeground" => theme.primary,
          "editorSuggestWidget.selectedBackground" => theme.selection,
          "peekView.border" => theme.accent_faint,
          "peekViewEditor.background" => theme.surface,
          "peekViewEditor.matchHighlightBackground" => theme.selection,
          "peekViewResult.background" => theme.raised,
          "peekViewResult.selectionBackground" => theme.selection,
          "diffEditor.insertedTextBackground" => "#{theme.wash}99",
          "diffEditor.removedTextBackground" => "#{theme.selection}99",
          "diffEditor.insertedLineBackground" => "#{theme.wash}55",
          "diffEditor.removedLineBackground" => "#{theme.selection}55",
          "panel.background" => theme.bg,
          "panel.border" => theme.border,
          "panelTitle.activeForeground" => theme.fg,
          "panelTitle.activeBorder" => theme.primary,
          "panelTitle.inactiveForeground" => theme.muted,
          "terminal.foreground" => theme.fg,
          "terminal.background" => theme.bg,
          "statusBar.background" => theme.raised,
          "statusBar.foreground" => theme.secondary,
          "statusBar.border" => theme.border,
          "statusBar.debuggingBackground" => theme.wash,
          "statusBar.debuggingForeground" => theme.fg,
          "statusBarItem.hoverBackground" => theme.border,
          "statusBarItem.remoteBackground" => theme.selection,
          "statusBarItem.remoteForeground" => theme.fg,
          "titleBar.activeBackground" => theme.surface,
          "titleBar.activeForeground" => theme.fg,
          "titleBar.inactiveBackground" => theme.surface,
          "titleBar.inactiveForeground" => theme.muted,
          "titleBar.border" => theme.border,
          "menu.background" => theme.surface,
          "menu.foreground" => theme.fg,
          "menu.selectionBackground" => theme.selection,
          "notifications.background" => theme.surface,
          "notifications.foreground" => theme.fg,
          "notifications.border" => theme.border,
          "notificationLink.foreground" => theme.primary,
          "breadcrumb.background" => theme.bg,
          "breadcrumb.foreground" => theme.muted,
          "breadcrumb.focusForeground" => theme.fg,
          "breadcrumb.activeSelectionForeground" => theme.primary,
          "minimap.background" => theme.bg,
          "minimap.selectionHighlight" => theme.selection,
          "scrollbar.shadow" => theme.dark? ? "#00000040" : "#00000012",
          "scrollbarSlider.background" => "#{theme.muted}33",
          "scrollbarSlider.hoverBackground" => "#{theme.muted}55",
          "gitDecoration.addedResourceForeground" => theme.accent_secondary,
          "gitDecoration.modifiedResourceForeground" => theme.primary,
          "gitDecoration.deletedResourceForeground" => theme.strong,
          "gitDecoration.renamedResourceForeground" => theme.accent_secondary,
          "gitDecoration.untrackedResourceForeground" => theme.accent_faint,
          "gitDecoration.ignoredResourceForeground" => theme.faint,
          "gitDecoration.conflictingResourceForeground" => theme.strong
        }.merge(terminal_ansi_colors(theme))
      end

      def terminal_ansi_colors(theme)
        theme.ansi.to_h do |name, value|
          suffix = name.to_s.split("_").map(&:capitalize).join
          key = suffix.start_with?("Bright") ? suffix.sub("Bright", "ansiBright") : "ansi#{suffix}"
          ["terminal.#{key}", value]
        end
      end

      def semantic_colors(theme)
        {
          "namespace" => theme.accent_secondary,
          "type" => theme.accent_secondary,
          "type.defaultLibrary" => theme.accent_secondary,
          "class" => theme.accent_secondary,
          "enum" => theme.accent_secondary,
          "interface" => theme.accent_secondary,
          "struct" => theme.accent_secondary,
          "typeParameter" => theme.accent_secondary,
          "parameter" => theme.fg,
          "variable" => theme.fg,
          "variable.readonly" => theme.fg,
          "property" => theme.fg,
          "enumMember" => theme.fg,
          "function" => {"foreground" => theme.fg, "bold" => true},
          "method" => theme.fg,
          "macro" => theme.accent_secondary,
          "keyword" => theme.primary,
          "modifier" => theme.primary,
          "comment" => {"foreground" => theme.muted, "italic" => true},
          "string" => theme.fg,
          "number" => theme.fg,
          "regexp" => theme.secondary,
          "operator" => theme.secondary,
          "decorator" => theme.accent_secondary,
          "*.deprecated" => {"foreground" => theme.muted, "strikethrough" => true}
        }
      end

      def vscode_readme(themes)
        names = themes.map { |theme| "- #{theme.name}" }.join("\n")
        <<~MARKDOWN
          # Lacold Theme

          Restrained monochrome Light and Dark themes generated by Lacold.

          #{names}

          Open **Preferences: Color Theme** and select a Lacold theme after
          installing the VSIX package.
        MARKDOWN
      end
    end
  end
end
