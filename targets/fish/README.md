# Lacold for Fish

Copy the `.theme` files into Fish's theme directory, then choose one with
Fish's native theme command:

```fish
mkdir -p ~/.config/fish/themes
cp themes/*.theme ~/.config/fish/themes/
fish_config theme choose lacold-air-blue
```

Add the `fish_config theme choose` command to `~/.config/fish/config.fish` to
select the theme in new shells. Do not source the theme file directly.

On Fish 4.3 or newer, each complete Lacold color family follows the terminal's
light or dark appearance automatically. Terminals that cannot report their
appearance use the dark variant. Pair the theme with the matching Lacold
terminal profile so its preferred background is available.
