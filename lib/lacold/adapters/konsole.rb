# frozen_string_literal: true

module Lacold
  module Adapters
    class Konsole < Base
      def id = "konsole"
      def name = "Konsole"
      def description = "KDE Konsole color schemes"

      def render(themes)
        files = themes.map { |theme| output("konsole/#{theme.id}.colorscheme", konsole_theme(theme)) }
        files << output("konsole/README.md", <<~MARKDOWN)
          # Lacold for Konsole

          Copy a `.colorscheme` file to `~/.local/share/konsole/`, then select
          it from the profile appearance settings.
        MARKDOWN
      end

      private

      def section(name, color, bold: false)
        "[#{name}]\nColor=#{rgb_line(color, ",")}\n#{"FontWeight=Bold\n" if bold}"
      end

      def konsole_theme(theme)
        normal = theme.ansi.values.first(8)
        bright = theme.ansi.values.last(8)
        sections = [section("Background", theme.bg), section("Foreground", theme.fg)]
        normal.each_with_index { |color, index| sections << section("Color#{index}", color) }
        bright.each_with_index { |color, index| sections << section("Color#{index}Intense", color, bold: true) }
        sections.join("\n") + <<~GENERAL

          [General]
          Description=#{theme.name}
          Opacity=1
          Wallpaper=
        GENERAL
      end
    end
  end
end
