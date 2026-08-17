# frozen_string_literal: true

module Lacold
  module Adapters
    class OpenCode < Base
      def id = "opencode"
      def name = "OpenCode"
      def description = "OpenCode custom theme JSON files"

      def render(themes)
        files = theme_families(themes).flat_map do |variants|
          if complete_mode_pair?(variants)
            by_mode = variants.to_h { |theme| [theme.mode, theme] }
            family = variants.first
            [output("opencode/#{family.family_id}.json", json(adaptive_theme(by_mode.fetch(:light), by_mode.fetch(:dark))))]
          else
            variants.map { |theme| output("opencode/#{theme.id}.json", json(single_mode_theme(theme))) }
          end
        end
        files << output("opencode/README.md", <<~MARKDOWN)
          # Lacold for OpenCode

          Copy a JSON file to `~/.config/opencode/themes/`, then set its basename
          as `theme` in your OpenCode configuration. Complete theme families
          include authored Light and Dark values in one adaptive JSON file.
        MARKDOWN
      end

      private

      def colors(theme)
        {
          "primary" => theme.primary, "secondary" => theme.accent_secondary,
          "accent" => theme.strong, "error" => theme.red,
          "warning" => theme.orange, "success" => theme.green,
          "info" => theme.accent_faint, "text" => theme.fg,
          "textMuted" => theme.muted, "background" => theme.bg,
          "backgroundPanel" => theme.surface, "backgroundElement" => theme.raised,
          "border" => theme.border, "borderActive" => theme.primary,
          "borderSubtle" => theme.line, "diffAdded" => theme.green,
          "diffRemoved" => theme.red, "diffContext" => theme.secondary,
          "diffHunkHeader" => theme.primary, "diffHighlightAdded" => theme.selection,
          "diffHighlightRemoved" => theme.inactive_selection,
          "diffAddedBg" => theme.green_wash, "diffRemovedBg" => theme.red_wash,
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
          "syntaxKeyword" => theme.syntax_color(:keyword, theme.primary),
          "syntaxFunction" => theme.syntax_color(:function, theme.fg),
          "syntaxVariable" => theme.syntax_color(:variable, theme.fg),
          "syntaxString" => theme.syntax_color(:string, theme.fg),
          "syntaxNumber" => theme.syntax_color(:number, theme.accent_secondary),
          "syntaxType" => theme.syntax_color(:type, theme.accent_secondary),
          "syntaxOperator" => theme.syntax_color(:operator, theme.secondary),
          "syntaxPunctuation" => theme.syntax_color(:punctuation, theme.secondary)
        }
      end

      def single_mode_theme(theme)
        definitions = colors(theme)
        pair = ->(color) { {"dark" => color, "light" => color} }
        {
          "$schema" => "https://opencode.ai/theme.json",
          "defs" => definitions,
          "theme" => definitions.keys.to_h { |name| [name, pair.call(name)] }
        }
      end

      def adaptive_theme(light, dark)
        by_mode = {"dark" => colors(dark), "light" => colors(light)}
        definitions = by_mode.flat_map do |mode, values|
          values.map { |name, value| ["#{mode}_#{name}", value] }
        end.to_h
        {
          "$schema" => "https://opencode.ai/theme.json",
          "defs" => definitions,
          "theme" => by_mode.fetch("dark").keys.to_h do |name|
            [name, {"dark" => "dark_#{name}", "light" => "light_#{name}"}]
          end
        }
      end
    end
  end
end
