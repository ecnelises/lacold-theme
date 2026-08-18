# frozen_string_literal: true

module Lacold
  module Adapters
    class Agy < Base
      def id = "agy"
      def name = "Agy"
      def kind = "integration"
      def description = "Antigravity CLI terminal-color integration"

      def render(themes)
        files = themes.map do |theme|
          output("agy/#{theme.id}.json", json({"colorScheme" => "terminal"}))
        end
        files << target_readme
      end
    end
  end
end
