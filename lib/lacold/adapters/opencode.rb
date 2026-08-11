# frozen_string_literal: true

module Lacold
  module Adapters
    class OpenCode < Base
      def id = "opencode"
      def name = "OpenCode"
      def description = "OpenCode custom theme JSON files"

      def render(themes)
        files = themes.map { |theme| output("opencode/#{theme.id}.json", json(opencode_theme(theme))) }
        files << output("opencode/README.md", <<~MARKDOWN)
          # Lacold for OpenCode

          Copy a JSON file to `~/.config/opencode/themes/`, then set its basename
          as `theme` in `~/.config/opencode/tui.json`.
        MARKDOWN
      end

      private

      def opencode_theme(theme)
        pair = ->(color) { {"dark" => color, "light" => color} }
        colors = {
          "primary" => theme.primary, "secondary" => theme.accent_secondary,
          "accent" => theme.strong, "error" => theme.strong,
          "warning" => theme.accent_secondary, "success" => theme.primary,
          "info" => theme.accent_faint, "text" => theme.fg,
          "textMuted" => theme.muted, "background" => theme.bg,
          "backgroundPanel" => theme.surface, "backgroundElement" => theme.raised,
          "border" => theme.border, "borderActive" => theme.primary,
          "borderSubtle" => theme.line, "diffAdded" => theme.accent_secondary,
          "diffRemoved" => theme.strong, "diffContext" => theme.secondary,
          "diffHunkHeader" => theme.primary, "diffHighlightAdded" => theme.selection,
          "diffHighlightRemoved" => theme.inactive_selection,
          "diffAddedBg" => theme.wash, "diffRemovedBg" => theme.wash,
          "diffContextBg" => theme.bg, "diffLineNumber" => theme.muted,
          "diffAddedLineNumberBg" => theme.selection,
          "diffRemovedLineNumberBg" => theme.inactive_selection,
          "markdownText" => theme.fg, "markdownHeading" => theme.primary,
          "markdownLink" => theme.primary, "markdownLinkText" => theme.accent_secondary,
          "markdownCode" => theme.fg, "markdownBlockQuote" => theme.muted,
          "markdownEmph" => theme.secondary, "markdownStrong" => theme.fg,
          "markdownHorizontalRule" => theme.border, "markdownListItem" => theme.primary,
          "markdownListEnumeration" => theme.accent_secondary,
          "markdownImage" => theme.primary, "markdownImageText" => theme.secondary,
          "markdownCodeBlock" => theme.fg, "syntaxComment" => theme.muted,
          "syntaxKeyword" => theme.primary, "syntaxFunction" => theme.fg,
          "syntaxVariable" => theme.fg, "syntaxString" => theme.fg,
          "syntaxNumber" => theme.accent_secondary, "syntaxType" => theme.accent_secondary,
          "syntaxOperator" => theme.secondary, "syntaxPunctuation" => theme.secondary
        }
        {
          "$schema" => "https://opencode.ai/theme.json",
          "defs" => colors,
          "theme" => colors.keys.to_h { |name| [name, pair.call(name)] }
        }
      end
    end
  end
end
