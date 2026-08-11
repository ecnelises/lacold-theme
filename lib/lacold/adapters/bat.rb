# frozen_string_literal: true

module Lacold
  module Adapters
    class Bat < Base
      include TextMate

      def id = "bat"
      def name = "Bat"
      def description = "TextMate themes loadable by bat"

      def render(themes)
        files = themes.map do |theme|
          output("bat/#{theme.id}.tmTheme", textmate(theme))
        end
        files << output("bat/README.md", <<~MARKDOWN)
          # Lacold for bat

          Copy a `.tmTheme` file to `$(bat --config-dir)/themes/`, run
          `bat cache --build`, then set `--theme=#{themes.first.id}` or choose
          another generated variant.
        MARKDOWN
      end
    end
  end
end

