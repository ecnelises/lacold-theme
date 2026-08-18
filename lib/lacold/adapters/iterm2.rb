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
        files = theme_families(themes).flat_map do |variants|
          if complete_mode_pair?(variants)
            by_mode = variants.to_h { |theme| [theme.mode, theme] }
            family = variants.first
            [output("iterm2/#{family.family_id}.itermcolors", adaptive_profile(by_mode.fetch(:light), by_mode.fetch(:dark)))]
          else
            variants.map { |theme| output("iterm2/#{theme.id}.itermcolors", profile(theme)) }
          end
        end
        files << target_readme
      end

      private

      def profile(theme)
        plist_document("<dict>\n#{color_entries(theme).join("\n")}\n</dict>")
      end

      def adaptive_profile(light, dark)
        colors = color_entries(light)
        colors.concat(color_entries(dark, suffix: " (Dark)"))
        colors.concat(color_entries(light, suffix: " (Light)"))
        colors << "  <key>Use Separate Colors for Light and Dark Mode</key>\n  <true/>"
        plist_document("<dict>\n#{colors.join("\n")}\n</dict>")
      end

      def color_entries(theme, suffix: "")
        entries = KEYS.map do |key, ansi_name|
          color_entry("#{key}#{suffix}", theme.ansi.fetch(ansi_name))
        end
        entries.concat([
          color_entry("Background Color#{suffix}", theme.bg),
          color_entry("Foreground Color#{suffix}", theme.fg),
          color_entry("Bold Color#{suffix}", theme.fg),
          color_entry("Cursor Color#{suffix}", theme.primary),
          color_entry("Cursor Text Color#{suffix}", theme.bg),
          color_entry("Selection Color#{suffix}", theme.selection),
          color_entry("Selected Text Color#{suffix}", theme.fg),
          color_entry("Link Color#{suffix}", theme.primary)
        ])
      end

      def color_entry(key, value)
        "  <key>#{key}</key>\n#{indent(plist_color_components(value), 2)}"
      end

      def indent(value, spaces)
        value.lines.map { |line| (" " * spaces) + line }.join.chomp
      end
    end
  end
end
