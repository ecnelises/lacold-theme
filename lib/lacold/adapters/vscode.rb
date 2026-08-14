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
          "description" => "Ink-first themes with restrained accents and clear semantic feedback.",
          "version" => Lacold::VERSION,
          "publisher" => "ecnelises",
          "license" => "MIT",
          "engines" => {"vscode" => "^1.75.0"},
          "categories" => ["Themes"],
          "keywords" => %w[theme light dark minimal ink semantic],
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
            settings = {"foreground" => foreground, "fontStyle" => style || ""}
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
          "errorForeground" => theme.red,
          "icon.foreground" => theme.secondary,
          "window.activeBorder" => theme.border,
          "window.inactiveBorder" => theme.surface,
          "selection.background" => theme.selection,
          "selection.foreground" => theme.selection_fg,
          "textLink.foreground" => theme.primary,
          "textLink.activeForeground" => theme.accent_secondary,
          "textBlockQuote.background" => theme.surface,
          "textBlockQuote.border" => theme.accent_faint,
          "textCodeBlock.background" => theme.surface,
          "textPreformat.foreground" => theme.fg,
          "textSeparator.foreground" => theme.border,
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
          "inputOption.activeForeground" => theme.selection_fg,
          "inputValidation.errorBackground" => theme.red_wash,
          "inputValidation.errorBorder" => theme.red,
          "inputValidation.warningBackground" => theme.orange_wash,
          "inputValidation.warningBorder" => theme.orange,
          "inputValidation.infoBackground" => theme.wash,
          "inputValidation.infoBorder" => theme.accent_secondary,
          "badge.background" => theme.selection,
          "badge.foreground" => theme.fg,
          "progressBar.background" => theme.primary,
          "list.activeSelectionBackground" => theme.selection,
          "list.activeSelectionForeground" => theme.fg,
          "list.inactiveSelectionBackground" => theme.inactive_selection,
          "list.inactiveSelectionForeground" => theme.fg,
          "list.hoverBackground" => theme.surface,
          "list.focusBackground" => theme.selection,
          "list.focusOutline" => "#{theme.primary}80",
          "list.highlightForeground" => theme.primary,
          "list.errorForeground" => theme.red,
          "list.warningForeground" => theme.orange,
          "listFilterWidget.background" => theme.inactive_selection,
          "listFilterWidget.outline" => theme.accent_faint,
          "tree.indentGuidesStroke" => theme.border,
          "activityBar.background" => theme.surface,
          "activityBar.foreground" => theme.fg,
          "activityBar.inactiveForeground" => theme.muted,
          "activityBar.border" => theme.border,
          "activityBar.activeBorder" => theme.primary,
          "activityBar.activeBackground" => theme.inactive_selection,
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
          "editorGroupHeader.noTabsBackground" => theme.bg,
          "editorGroup.border" => theme.border,
          "tab.activeBackground" => theme.bg,
          "tab.activeForeground" => theme.fg,
          "tab.activeBorderTop" => theme.primary,
          "tab.inactiveBackground" => theme.surface,
          "tab.inactiveForeground" => theme.muted,
          "tab.border" => theme.border,
          "tab.hoverBackground" => theme.inactive_selection,
          "tab.unfocusedActiveForeground" => theme.secondary,
          "tab.unfocusedInactiveForeground" => theme.faint,
          "editor.background" => theme.bg,
          "editor.foreground" => theme.fg,
          "editorLineNumber.foreground" => theme.line_nr,
          "editorLineNumber.activeForeground" => theme.line_nr_active,
          "editorCursor.foreground" => theme.caret,
          "editor.selectionBackground" => theme.selection,
          "editor.inactiveSelectionBackground" => theme.inactive_selection,
          "editor.selectionHighlightBackground" => "#{theme.selection}80",
          "editor.wordHighlightBackground" => "#{theme.bracket}80",
          "editor.wordHighlightStrongBackground" => "#{theme.selection}B3",
          "editor.findMatchBackground" => theme.yellow_wash,
          "editor.findMatchBorder" => theme.yellow,
          "editor.findMatchHighlightBackground" => "#{theme.yellow_wash}80",
          "editor.findRangeHighlightBackground" => "#{theme.surface}80",
          "editor.hoverHighlightBackground" => "#{theme.selection}80",
          "editor.lineHighlightBackground" => theme.line,
          "editor.lineHighlightBorder" => "#00000000",
          "editorLink.activeForeground" => theme.primary,
          "editorWhitespace.foreground" => theme.whitespace,
          "editorIndentGuide.background1" => theme.border,
          "editorIndentGuide.activeBackground1" => theme.accent_faint,
          "editorRuler.foreground" => theme.border,
          "editorCodeLens.foreground" => theme.muted,
          "editorBracketMatch.background" => theme.bracket,
          "editorBracketMatch.border" => theme.accent_faint,
          "editorBracketHighlight.foreground1" => theme.secondary,
          "editorBracketHighlight.foreground2" => theme.primary,
          "editorBracketHighlight.foreground3" => theme.muted,
          "editorBracketHighlight.foreground4" => theme.accent_secondary,
          "editorBracketHighlight.foreground5" => theme.secondary,
          "editorBracketHighlight.foreground6" => theme.accent_faint,
          "editorBracketHighlight.unexpectedBracket.foreground" => theme.red,
          "editorGutter.background" => theme.bg,
          "editorGutter.addedBackground" => theme.green,
          "editorGutter.modifiedBackground" => theme.primary,
          "editorGutter.deletedBackground" => theme.red,
          "editorOverviewRuler.border" => theme.border,
          "editorOverviewRuler.errorForeground" => theme.red,
          "editorOverviewRuler.warningForeground" => theme.orange,
          "editorOverviewRuler.infoForeground" => theme.primary,
          "editorError.foreground" => theme.red,
          "editorError.background" => "#{theme.red_wash}00",
          "editorWarning.foreground" => theme.orange,
          "editorWarning.background" => "#{theme.orange_wash}00",
          "editorInfo.foreground" => theme.primary,
          "editorHint.foreground" => theme.green,
          "editorUnnecessaryCode.opacity" => "#00000066",
          "editorWidget.background" => theme.surface,
          "editorWidget.foreground" => theme.fg,
          "editorWidget.border" => theme.border,
          "editorSuggestWidget.background" => theme.surface,
          "editorSuggestWidget.border" => theme.border,
          "editorSuggestWidget.foreground" => theme.fg,
          "editorSuggestWidget.highlightForeground" => theme.primary,
          "editorSuggestWidget.selectedBackground" => theme.selection,
          "editorHoverWidget.background" => theme.surface,
          "editorHoverWidget.border" => theme.border,
          "peekView.border" => theme.accent_faint,
          "peekViewEditor.background" => theme.surface,
          "peekViewEditor.matchHighlightBackground" => theme.yellow_wash,
          "peekViewResult.background" => theme.raised,
          "peekViewResult.matchHighlightBackground" => theme.yellow_wash,
          "peekViewResult.selectionBackground" => theme.selection,
          "peekViewTitle.background" => theme.surface,
          "diffEditor.insertedTextBackground" => "#{theme.green_wash}99",
          "diffEditor.removedTextBackground" => "#{theme.red_wash}99",
          "diffEditor.insertedLineBackground" => "#{theme.green_wash}66",
          "diffEditor.removedLineBackground" => "#{theme.red_wash}66",
          "diffEditor.diagonalFill" => theme.border,
          "panel.background" => theme.bg,
          "panel.border" => theme.border,
          "panelTitle.activeForeground" => theme.fg,
          "panelTitle.activeBorder" => theme.primary,
          "panelTitle.inactiveForeground" => theme.muted,
          "terminal.foreground" => theme.fg,
          "terminal.background" => theme.bg,
          "terminalCursor.foreground" => theme.caret,
          "terminal.selectionBackground" => theme.selection,
          "statusBar.background" => theme.raised,
          "statusBar.foreground" => theme.secondary,
          "statusBar.border" => theme.border,
          "statusBar.debuggingBackground" => theme.orange_wash,
          "statusBar.debuggingForeground" => theme.selection_fg,
          "statusBar.noFolderBackground" => theme.surface,
          "statusBar.noFolderForeground" => theme.secondary,
          "statusBarItem.activeBackground" => theme.selection,
          "statusBarItem.hoverBackground" => theme.border,
          "statusBarItem.prominentBackground" => theme.selection,
          "statusBarItem.prominentForeground" => theme.selection_fg,
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
          "menu.selectionForeground" => theme.selection_fg,
          "menu.separatorBackground" => theme.border,
          "notifications.background" => theme.surface,
          "notifications.foreground" => theme.fg,
          "notifications.border" => theme.border,
          "notificationLink.foreground" => theme.primary,
          "breadcrumb.background" => theme.bg,
          "breadcrumb.foreground" => theme.muted,
          "breadcrumb.focusForeground" => theme.fg,
          "breadcrumb.activeSelectionForeground" => theme.primary,
          "minimap.background" => theme.bg,
          "minimap.selectionHighlight" => "#{theme.accent_faint}80",
          "minimap.findMatchHighlight" => "#{theme.yellow}99",
          "scrollbar.shadow" => theme.dark? ? "#00000040" : "#00000012",
          "scrollbarSlider.background" => "#{theme.muted}33",
          "scrollbarSlider.hoverBackground" => "#{theme.muted}55",
          "scrollbarSlider.activeBackground" => "#{theme.secondary}66",
          "gitDecoration.addedResourceForeground" => theme.green,
          "gitDecoration.modifiedResourceForeground" => theme.primary,
          "gitDecoration.deletedResourceForeground" => theme.red,
          "gitDecoration.renamedResourceForeground" => theme.accent_secondary,
          "gitDecoration.untrackedResourceForeground" => theme.green,
          "gitDecoration.ignoredResourceForeground" => theme.faint,
          "gitDecoration.conflictingResourceForeground" => theme.orange
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
          "event" => theme.fg,
          "function" => theme.fg,
          "method" => theme.fg,
          "macro" => theme.accent_secondary,
          "label" => theme.primary,
          "keyword" => theme.primary,
          "modifier" => theme.primary,
          "comment" => {"foreground" => theme.muted, "italic" => true},
          "string" => theme.fg,
          "number" => theme.fg,
          "regexp" => theme.fg,
          "operator" => theme.secondary,
          "decorator" => theme.accent_secondary,
          "*.deprecated" => {"foreground" => theme.muted, "strikethrough" => true}
        }
      end

      def vscode_readme(themes)
        names = themes.map { |theme| "- #{theme.name}" }.join("\n")
        <<~MARKDOWN
          # Lacold Theme

          Ink-first Light and Dark themes with restrained structural accents
          and clear semantic feedback colors, generated by Lacold.

          #{names}

          Open **Preferences: Color Theme** and select a Lacold theme after
          installing the VSIX package.
        MARKDOWN
      end
    end
  end
end
