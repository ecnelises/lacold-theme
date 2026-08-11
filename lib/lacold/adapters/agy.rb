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
        files << output("agy/README.md", <<~MARKDOWN)
          # Lacold for Agy

          Agy is the Antigravity CLI. Merge the selected snippet into its
          settings and use the matching Lacold terminal profile. The `terminal`
          setting tells Agy to inherit the terminal's carefully authored palette.
        MARKDOWN
      end
    end
  end
end
