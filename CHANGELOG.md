# Changelog

## Unreleased

- Align Air neutrals with the current iA editor palette.
- Separate structural accents from semantic diagnostics, diffs, search, cursor,
  Fish, and terminal ANSI colors.
- Preserve the local iA Vim/Emacs/Fish/Kitty/VS Code UI coverage while keeping
  generated adapters as the single source of color values.
- Make cursor colors follow each Lacold Air accent instead of sharing the Blue
  iA cyan cursor across all variants.
- Merge complete Vim/NeoVim, OpenCode, and iTerm2 Light/Dark families into
  adaptive artifacts while preserving single-mode filtered builds.
- Add Kitty auto-appearance bundles for each complete Air color family.
- Add Lacold Air Rainbow Light and Dark: a blue-cyan interface anchor with a
  seven-hue syntax spectrum plus explicit ink and gray lanes.

## 0.1.0

- Add the Air background collection with five monochrome accents and Light/Dark modes.
- Add the static palette catalog, generator CLI, validation, and deterministic manifest.
- Add all 27 adapters covering the 28 named carriers (Vim and NeoVim share one compatible output).
- Cover core Emacs UI and editing faces plus Org, Magit, Corfu, Company, and Vertico.
- Add the interactive GitHub Pages specimen and release automation.
