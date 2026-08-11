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
              # Merge this table into ~/.codex/config.toml.
              [tui]
              theme = "#{theme.id}"
            TOML
          ]
        end
        files << output("codex/README.md", <<~MARKDOWN)
          # Lacold for Codex CLI

          Copy the desired `.tmTheme` file to `$CODEX_HOME/themes/` (normally
          `~/.codex/themes/`), then merge the matching TOML snippet into
          `~/.codex/config.toml`. Codex syntax colors use the Lacold theme while
          the surrounding terminal background comes from your Lacold terminal
          profile.

          The `tui.theme` setting is documented in the official Codex
          configuration reference: <https://developers.openai.com/codex/config-reference/>.
        MARKDOWN
      end
    end
  end
end
