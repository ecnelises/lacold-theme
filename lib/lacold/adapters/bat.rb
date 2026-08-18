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
        files << target_readme
      end
    end
  end
end
