# Lacold

Lacold is a restrained, generated theme family for editors, terminals, and
developer tools. Its visual grammar absorbs the former local iA editor themes:
neutral colors carry text and interface hierarchy, authored chromatic roles
carry structure, and a small fixed semantic palette is reserved for feedback.

The first collection is **Air**. It has five hand-authored monochrome families
— Blue, Green, Orange, Pink, and Purple — plus the restrained multi-hue Rainbow.
Each has independent Light and Dark palettes, producing twelve official variants:

```text
Lacold Air Blue Light       Lacold Air Blue Dark
Lacold Air Green Light      Lacold Air Green Dark
Lacold Air Orange Light     Lacold Air Orange Dark
Lacold Air Pink Light       Lacold Air Pink Dark
Lacold Air Purple Light     Lacold Air Purple Dark
Lacold Air Rainbow Light    Lacold Air Rainbow Dark
```

## Design contract

Lacold is ink-first, not monochrome. Normal syntax and interface hierarchy stay
neutral; keywords, navigation, and selection use authored accents. Diagnostics,
diffs, search, terminal ANSI colors, and shell state continue to use fixed
semantic roles independent of the structural palette.

Rainbow keeps the interface, cursor, and selection on a calm blue-cyan axis. Its
syntax palette has seven chromatic lanes: red attributes and properties, orange
numbers and tags, yellow constants and symbols, green strings and regular
expressions, cyan functions, blue types, and violet keywords. Two neutral lanes
complete the palette: mode-aware ink for variables and gray for operators and
punctuation. This makes Rainbow visibly colorful without assigning a different
hue to every token.

Air's neutral structure is based on that iA palette. Each accent
defines `strong`, `primary`, `secondary`, `faint`, `wash`, `selection`,
`inactive_selection`, and `bracket` values separately for Light and Dark. A
separate Light/Dark semantic palette supplies status, wash, and terminal roles;
the cursor follows each variant's authored primary accent. Rainbow additionally
defines an explicit seven-hue spectrum plus ink and gray. No color-generation
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

When both modes are selected, Vim/NeoVim, OpenCode, and iTerm2 emit one adaptive
artifact per Air color family. Vim follows `background`, OpenCode uses native
`dark`/`light` color pairs, and iTerm2 stores both profile color sets. Kitty also
emits ready-to-install `dark-theme.auto.conf` and `light-theme.auto.conf` bundles.

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
asset. A release tag must match `Lacold::VERSION`, for example `v0.1.0` for
version `0.1.0`.

When the repository secret `VSCE_PAT` is configured, the tagged VSIX is also
published to the Visual Studio Marketplace. When `OVSX_PAT` is configured, the
same VSIX is published to Open VSX. Missing marketplace secrets simply skip the
corresponding publishing step; GitHub Release creation still proceeds normally.

## License

MIT — see [LICENSE](LICENSE).
