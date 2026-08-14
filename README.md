# Lacold

Lacold is a restrained, generated theme family for editors, terminals, and
developer tools. Its visual grammar absorbs the former local iA editor themes:
neutral colors carry text and interface hierarchy, the selected chromatic
family carries structure, and a small fixed semantic palette is reserved for
feedback.

The first collection is **Air**. It has five hand-authored foreground families
— Blue, Green, Orange, Pink, and Purple — with independent Light and Dark
palettes. That produces ten official variants:

```text
Lacold Air Blue Light       Lacold Air Blue Dark
Lacold Air Green Light      Lacold Air Green Dark
Lacold Air Orange Light     Lacold Air Orange Dark
Lacold Air Pink Light       Lacold Air Pink Dark
Lacold Air Purple Light     Lacold Air Purple Dark
```

## Design contract

Lacold is ink-first, not monochrome. Normal syntax and interface hierarchy stay
neutral; keywords, navigation, and selection use the chosen accent. Conventional
red, orange, yellow, green, purple, and cyan appear only when semantics benefit
from them: diagnostics, diffs, search, terminal ANSI colors, and shell state.

Air's neutral structure is based on that iA palette. Each accent
defines `strong`, `primary`, `secondary`, `faint`, `wash`, `selection`,
`inactive_selection`, and `bracket` values separately for Light and Dark. A
separate Light/Dark semantic palette supplies status, wash, and terminal roles;
the cursor follows each variant's authored primary accent. No color-generation
algorithm changes authored palette values.

## Generate themes

Lacold uses Ruby 3.2 or newer and has no runtime gem dependencies.

```sh
bin/lacold list
bin/lacold build
bin/lacold build --target vim,kitty --color pink --mode dark
bin/lacold check
bin/lacold site
```

The default build writes to `dist/`. Generated files are release artifacts and
are not committed to the repository. Use `--output` to select another directory.

Available adapters in v0.1:

- CotEditor
- Terminal.app
- iTerm2
- Vim and NeoVim
- Emacs
- Visual Studio
- Visual Studio Code
- IntelliJ Platform
- Kitty
- Fish
- bat
- fzf
- Codex CLI
- OpenCode
- Nano
- DrRacket
- Zed
- Tmux
- Zellij
- Agy (Antigravity CLI, inheriting terminal colors)
- BTop
- Xcode
- Gedit
- Kate
- GNOME Terminal
- Windows Terminal
- Konsole

## Development

```sh
bundle install
bundle exec rake check
bundle exec rake build
bundle exec rake site
```

`rake check` validates the palette matrix, contrast requirements, parsable
output, manifest completeness, and deterministic generation. The static demo is
built into `_site/` and deployed through GitHub Pages.

Releases are built from version tags. Each target receives a compressed archive,
the VS Code target also receives a VSIX, and `SHA256SUMS` covers every published
asset.

## License

MIT — see [LICENSE](LICENSE).
