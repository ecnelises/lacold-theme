# frozen_string_literal: true

module Lacold
  module Adapters
    class TerminalApp < Base
      KEYS = {
        "ANSIBlackColor" => :black,
        "ANSIRedColor" => :red,
        "ANSIGreenColor" => :green,
        "ANSIYellowColor" => :yellow,
        "ANSIBlueColor" => :blue,
        "ANSIMagentaColor" => :magenta,
        "ANSICyanColor" => :cyan,
        "ANSIWhiteColor" => :white,
        "ANSIBrightBlackColor" => :bright_black,
        "ANSIBrightRedColor" => :bright_red,
        "ANSIBrightGreenColor" => :bright_green,
        "ANSIBrightYellowColor" => :bright_yellow,
        "ANSIBrightBlueColor" => :bright_blue,
        "ANSIBrightMagentaColor" => :bright_magenta,
        "ANSIBrightCyanColor" => :bright_cyan,
        "ANSIBrightWhiteColor" => :bright_white
      }.freeze

      def id = "terminal-app"
      def name = "Terminal.app"
      def description = "Importable macOS Terminal profiles with archived NSColor values"

      def render(themes)
        files = themes.map do |theme|
          output("terminal-app/#{theme.id}.terminal", profile(theme))
        end
        files << output("terminal-app/README.md", <<~MARKDOWN)
          # Lacold for Terminal.app

          Double-click a `.terminal` file to import it, then choose the profile
          under **Terminal → Settings → Profiles**. The imported profile does not
          change your font or shell.
        MARKDOWN
      end

      private

      def profile(theme)
        colors = KEYS.map do |key, ansi_name|
          color_data(key, theme.ansi.fetch(ansi_name))
        end
        colors.concat([
          color_data("BackgroundColor", theme.bg),
          color_data("TextColor", theme.fg),
          color_data("TextBoldColor", theme.fg),
          color_data("CursorColor", theme.primary),
          color_data("SelectionColor", theme.selection)
        ])
        body = <<~XML
          <dict>
            <key>FontAntialias</key>
            <true/>
            <key>ProfileCurrentVersion</key>
            <real>2.07</real>
            <key>UseBrightBold</key>
            <true/>
            <key>name</key>
            <string>#{xml(theme.name)}</string>
            <key>type</key>
            <string>Window Settings</string>
          #{colors.join("\n")}
          </dict>
        XML
        plist_document(body)
      end

      def color_data(key, value)
        encoded = [BinaryPlist.keyed_color(value)].pack("m0").scan(/.{1,68}/).join("\n      ")
        "  <key>#{key}</key>\n  <data>\n      #{encoded}\n  </data>"
      end
    end
  end
end
