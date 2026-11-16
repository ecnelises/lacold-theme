# Source this file; lacold is a shell function, not an installed executable.
_LACOLD_ROOT=${${(%):-%x}:A:h}

_lacold_backend() {
  command ruby -I "$_LACOLD_ROOT/lib" -rlacold/shell -e 'exit Lacold::Shell.run(ARGV)' -- "$@"
}

_lacold_refresh() {
  local lacold_code
  lacold_code=$(_lacold_backend _session zsh) || return
  eval "$lacold_code"
}

lacold() {
  _lacold_backend "$@" || return
  case "${1-}" in
    install|use|set|reset|remove|reload) _lacold_refresh ;;
  esac
}

_lacold_complete() {
  local -a choices
  if (( CURRENT == 2 )); then
    choices=(list status variants show install use set reset remove reload migrate help)
  elif (( CURRENT == 3 )); then
    choices=(all vscode vim iterm2 terminal-app kitty bat fzf codex coteditor emacs visual-studio intellij nano dr-racket zed xcode gedit kate fish opencode tmux zellij agy btop gnome-terminal windows-terminal konsole)
  else
    choices=(blue green orange pink purple rainbow light dark auto --color --mode)
  fi
  compadd -- $choices
}
if (( $+functions[compdef] )); then
  compdef _lacold_complete lacold
fi
_lacold_refresh
