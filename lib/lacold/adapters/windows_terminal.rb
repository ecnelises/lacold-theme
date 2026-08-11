# frozen_string_literal: true

module Lacold
  module Adapters
    class WindowsTerminal < Base
      def id = "windows-terminal"
      def name = "Windows Terminal"
      def description = "Windows Terminal color schemes"

      def render(themes)
        files = themes.map do |theme|
          output("windows-terminal/#{theme.id}.json", json(scheme(theme)))
        end
        files << output("windows-terminal/README.md", <<~MARKDOWN)
          # Lacold for Windows Terminal

          Add the object from the selected JSON file to `schemes` in Windows
          Terminal's `settings.json`, then set the profile's `colorScheme` to
          the object's `name`.
        MARKDOWN
      end

      private

      def scheme(theme)
        ansi = theme.ansi
        {
          "name" => theme.name,
          "background" => theme.bg, "foreground" => theme.fg,
          "cursorColor" => theme.primary, "selectionBackground" => theme.selection,
          "black" => ansi[:black], "red" => ansi[:red], "green" => ansi[:green],
          "yellow" => ansi[:yellow], "blue" => ansi[:blue], "purple" => ansi[:magenta],
          "cyan" => ansi[:cyan], "white" => ansi[:white],
          "brightBlack" => ansi[:bright_black], "brightRed" => ansi[:bright_red],
          "brightGreen" => ansi[:bright_green], "brightYellow" => ansi[:bright_yellow],
          "brightBlue" => ansi[:bright_blue], "brightPurple" => ansi[:bright_magenta],
          "brightCyan" => ansi[:bright_cyan], "brightWhite" => ansi[:bright_white]
        }
      end
    end
  end
end
