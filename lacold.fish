# Source this file; lacold is a shell function, not an installed executable.
set -g _LACOLD_ROOT (path dirname (status filename))
set -g _LACOLD_ROOT (path resolve $_LACOLD_ROOT)

function _lacold_backend
    command ruby -I "$_LACOLD_ROOT/lib" -rlacold/shell -e 'exit Lacold::Shell.run(ARGV)' -- $argv
end

function _lacold_refresh
    if set -q _LACOLD_REFRESHING
        return
    end
    set -g _LACOLD_REFRESHING 1
    set -l lacold_code (_lacold_backend _session fish | string collect)
    if test $pipestatus[1] -ne 0
        set -e _LACOLD_REFRESHING
        return 1
    end
    eval $lacold_code
    set -l lacold_result $status
    set -e _LACOLD_REFRESHING
    return $lacold_result
end

function lacold --description 'Manage Lacold themes and palette colors'
    _lacold_backend $argv
    or return
    if contains -- "$argv[1]" install use set reset remove reload
        _lacold_refresh
    end
end

# Fish reports appearance changes without a poller or background daemon.
function _lacold_appearance_changed --on-variable fish_terminal_color_theme
    if test "$fish_terminal_color_theme" = light
        set -gx LACOLD_APPEARANCE light
    else
        set -gx LACOLD_APPEARANCE dark
    end
    _lacold_refresh
end

complete -c lacold -f
complete -c lacold -n 'not __fish_seen_subcommand_from list status variants show install use set reset remove reload migrate help' -a 'list status variants show install use set reset remove reload migrate help'
complete -c lacold -n '__fish_seen_subcommand_from show install use set reset remove reload' -a 'all vscode vim iterm2 terminal-app kitty bat fzf codex coteditor emacs visual-studio intellij nano dr-racket zed xcode gedit kate fish opencode tmux zellij agy btop gnome-terminal windows-terminal konsole'
complete -c lacold -l color -xa 'blue green orange pink purple rainbow'
complete -c lacold -l mode -xa 'light dark auto'
complete -c lacold -n '__fish_seen_subcommand_from migrate' -l dry-run
_lacold_appearance_changed
