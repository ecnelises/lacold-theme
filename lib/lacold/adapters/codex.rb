# frozen_string_literal: true

module Lacold
  module Adapters
    class Codex < Base
      include TextMate

      def id = "codex"
      def name = "Codex CLI"
      def kind = "integration"
      def description = "Codex .tmTheme files and config.toml snippets"

      def render(themes)
        files = themes.flat_map do |theme|
          [
            output("codex/themes/#{theme.id}.tmTheme", textmate(theme)),
            output("codex/config/#{theme.id}.toml", <<~TOML)
              # Merge this table into $CODEX_HOME/config.toml
              # (normally ~/.codex/config.toml).
              [tui]
              theme = "#{theme.id}"
            TOML
          ]
        end
        files << target_readme
      end
    end
  end
end
