# frozen_string_literal: true

module Lacold
  module Adapters
    class ITerm2 < Base
      KEYS = {
        "Ansi 0 Color" => :black,
        "Ansi 1 Color" => :red,
        "Ansi 2 Color" => :green,
        "Ansi 3 Color" => :yellow,
        "Ansi 4 Color" => :blue,
        "Ansi 5 Color" => :magenta,
        "Ansi 6 Color" => :cyan,
        "Ansi 7 Color" => :white,
        "Ansi 8 Color" => :bright_black,
        "Ansi 9 Color" => :bright_red,
        "Ansi 10 Color" => :bright_green,
        "Ansi 11 Color" => :bright_yellow,
        "Ansi 12 Color" => :bright_blue,
        "Ansi 13 Color" => :bright_magenta,
        "Ansi 14 Color" => :bright_cyan,
        "Ansi 15 Color" => :bright_white
      }.freeze

      def id = "iterm2"
      def name = "iTerm2"
      def description = "Importable .itermcolors profiles"

      def render(themes)
        files = themes.map do |theme|
          output("iterm2/#{theme.id}.itermcolors", profile(theme))
        end
        files << output("iterm2/README.md", <<~MARKDOWN)
          # Lacold for iTerm2

          Open **Settings → Profiles → Colors → Color Presets → Import**, choose
          the desired `.itermcolors` file, then select it from Color Presets.
        MARKDOWN
      end

      private

      def profile(theme)
        colors = KEYS.map do |key, ansi_name|
          "  <key>#{key}</key>\n#{indent(plist_color_components(theme.ansi.fetch(ansi_name)), 2)}"
        end
        colors.concat([
          "  <key>Background Color</key>\n#{indent(plist_color_components(theme.bg), 2)}",
          "  <key>Foreground Color</key>\n#{indent(plist_color_components(theme.fg), 2)}",
          "  <key>Bold Color</key>\n#{indent(plist_color_components(theme.fg), 2)}",
          "  <key>Cursor Color</key>\n#{indent(plist_color_components(theme.primary), 2)}",
          "  <key>Cursor Text Color</key>\n#{indent(plist_color_components(theme.bg), 2)}",
          "  <key>Selection Color</key>\n#{indent(plist_color_components(theme.selection), 2)}",
          "  <key>Selected Text Color</key>\n#{indent(plist_color_components(theme.fg), 2)}",
          "  <key>Link Color</key>\n#{indent(plist_color_components(theme.primary), 2)}"
        ])
        plist_document("<dict>\n#{colors.join("\n")}\n</dict>")
      end

      def indent(value, spaces)
        value.lines.map { |line| (" " * spaces) + line }.join.chomp
      end
    end
  end
end

