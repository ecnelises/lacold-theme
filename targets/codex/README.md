# Lacold for Codex CLI

Generate a Codex theme directly:

```sh
bin/lacold build --target codex --color blue --mode dark
```

Copy the desired file from `dist/codex/themes/` to
`$CODEX_HOME/themes/` (normally `~/.codex/themes/`). Then merge its matching
snippet from `dist/codex/config/` into `$CODEX_HOME/config.toml` (normally
`~/.codex/config.toml`):

```toml
[tui]
theme = "lacold-air-blue-dark"
```

The theme name is the `.tmTheme` filename without its extension. Pair it with
a Lacold terminal profile so Codex's surrounding terminal colors match.
