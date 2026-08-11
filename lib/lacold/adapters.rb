# frozen_string_literal: true

require_relative "adapters/base"
require_relative "adapters/text_mate"
require_relative "adapters/vim"
require_relative "adapters/vscode"
require_relative "adapters/iterm2"
require_relative "adapters/terminal_app"
require_relative "adapters/kitty"
require_relative "adapters/bat"
require_relative "adapters/fzf"
require_relative "adapters/codex"
require_relative "adapters/coteditor"
require_relative "adapters/emacs"
require_relative "adapters/visual_studio"
require_relative "adapters/intellij"
require_relative "adapters/nano"
require_relative "adapters/dr_racket"
require_relative "adapters/zed"
require_relative "adapters/xcode"
require_relative "adapters/gedit"
require_relative "adapters/kate"
require_relative "adapters/fish"
require_relative "adapters/opencode"
require_relative "adapters/tmux"
require_relative "adapters/zellij"
require_relative "adapters/agy"
require_relative "adapters/btop"
require_relative "adapters/gnome_terminal"
require_relative "adapters/windows_terminal"
require_relative "adapters/konsole"

module Lacold
  module Adapters
    module_function

    def all
      @all ||= [
        VSCode.new,
        Vim.new,
        ITerm2.new,
        TerminalApp.new,
        Kitty.new,
        Bat.new,
        Fzf.new,
        Codex.new,
        CotEditor.new,
        Emacs.new,
        VisualStudio.new,
        IntelliJ.new,
        Nano.new,
        DrRacket.new,
        Zed.new,
        Xcode.new,
        Gedit.new,
        Kate.new,
        Fish.new,
        OpenCode.new,
        Tmux.new,
        Zellij.new,
        Agy.new,
        BTop.new,
        GnomeTerminal.new,
        WindowsTerminal.new,
        Konsole.new
      ].freeze
    end

    def ids
      all.map(&:id)
    end

    def find(id)
      normalized = id.to_s.downcase
      normalized = "vim" if normalized == "neovim"
      normalized = "terminal-app" if %w[terminal terminalapp].include?(normalized)
      normalized = "visual-studio" if %w[vs visualstudio].include?(normalized)
      normalized = "dr-racket" if %w[drracket dr_racket].include?(normalized)
      normalized = "gnome-terminal" if %w[gnometerminal gnome_terminal].include?(normalized)
      normalized = "windows-terminal" if %w[windowsterminal windows_terminal].include?(normalized)
      all.find { |adapter| adapter.id == normalized } ||
        raise(Error, "unknown target: #{id} (available: #{ids.join(', ')})")
    end
  end
end
