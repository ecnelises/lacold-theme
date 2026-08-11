# frozen_string_literal: true

module Lacold
  module Adapters
    class CotEditor < Base
      def id = "coteditor"
      def name = "CotEditor"
      def description = "CotEditor .cottheme files"

      def render(themes)
        files = themes.map { |theme| output("coteditor/#{theme.id}.cottheme", json(coteditor_theme(theme))) }
        files << output("coteditor/README.md", <<~MARKDOWN)
          # Lacold for CotEditor

          Double-click a `.cottheme` file to import it, or copy it into
          CotEditor's user Themes directory. Select it in CotEditor settings.
        MARKDOWN
      end

      private

      def color(value, system: nil)
        result = {"color" => value}
        result["usesSystemSetting"] = system unless system.nil?
        result
      end

      def coteditor_theme(theme)
        {
          "attributes" => color(theme.accent_secondary),
          "background" => color(theme.bg),
          "characters" => color(theme.fg),
          "commands" => color(theme.primary),
          "comments" => color(theme.muted),
          "highlight" => color(theme.wash, system: false),
          "insertionPoint" => color(theme.primary, system: false),
          "invisibles" => color(theme.whitespace),
          "keywords" => color(theme.primary),
          "lineHighlight" => color(theme.line),
          "metadata" => {
            "author" => "Lacold contributors",
            "description" => "#{theme.name}; neutral foundation with one authored hue.",
            "license" => "MIT"
          },
          "numbers" => color(theme.accent_secondary),
          "selection" => color(theme.selection, system: false),
          "strings" => color(theme.fg),
          "text" => color(theme.fg),
          "types" => color(theme.accent_secondary),
          "values" => color(theme.fg),
          "variables" => color(theme.primary)
        }
      end
    end
  end
end
