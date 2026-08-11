# frozen_string_literal: true

module Lacold
  module Adapters
    class Vim < Base
      def id = "vim"
      def name = "Vim / NeoVim"
      def description = "Vim colorschemes compatible with Vim 8+ and NeoVim"

      def render(themes)
        outputs = themes.map do |theme|
          output("vim/colors/#{theme.id}.vim", vim_theme(theme))
        end
        outputs << output("vim/README.md", <<~MARKDOWN)
          # Lacold for Vim and NeoVim

          Copy the desired file from `colors/` into `~/.vim/colors/` or
          `~/.config/nvim/colors/`, then run `:colorscheme lacold-air-blue-light`
          (replace the color and mode as needed).

          The files include true-color values and restrained xterm-256 fallbacks.
        MARKDOWN
        outputs
      end

      private

      def vim_theme(theme)
        groups = [
          ["Normal", theme.fg, theme.bg, "NONE"],
          ["NormalNC", theme.fg, theme.bg, "NONE"],
          ["NormalFloat", theme.fg, theme.surface, "NONE"],
          ["FloatBorder", theme.border, theme.surface, "NONE"],
          ["FloatTitle", theme.primary, theme.surface, "bold"],
          ["Cursor", theme.bg, theme.primary, "NONE"],
          ["CursorLine", "NONE", theme.line, "NONE"],
          ["CursorColumn", "NONE", theme.line, "NONE"],
          ["ColorColumn", "NONE", theme.surface, "NONE"],
          ["Visual", "NONE", theme.selection, "NONE"],
          ["VisualNOS", "NONE", theme.inactive_selection, "NONE"],
          ["Search", theme.strong, theme.wash, "bold"],
          ["CurSearch", theme.bg, theme.strong, "bold"],
          ["IncSearch", theme.bg, theme.strong, "bold"],
          ["MatchParen", theme.primary, theme.bracket, "bold"],
          ["LineNr", theme.line_nr, theme.bg, "NONE"],
          ["CursorLineNr", theme.line_nr_active, theme.line, "bold"],
          ["SignColumn", theme.muted, theme.bg, "NONE"],
          ["FoldColumn", theme.muted, theme.bg, "NONE"],
          ["Folded", theme.secondary, theme.surface, "NONE"],
          ["NonText", theme.whitespace, "NONE", "NONE"],
          ["Whitespace", theme.whitespace, "NONE", "NONE"],
          ["WinSeparator", theme.border, "NONE", "NONE"],
          ["Pmenu", theme.secondary, theme.surface, "NONE"],
          ["PmenuSel", theme.fg, theme.selection, "bold"],
          ["PmenuKind", theme.accent_secondary, theme.surface, "NONE"],
          ["PmenuKindSel", theme.primary, theme.selection, "bold"],
          ["StatusLine", theme.fg, theme.raised, "NONE"],
          ["StatusLineNC", theme.muted, theme.surface, "NONE"],
          ["TabLine", theme.muted, theme.surface, "NONE"],
          ["TabLineSel", theme.fg, theme.bg, "bold"],
          ["Title", theme.fg, "NONE", "bold"],
          ["Directory", theme.primary, "NONE", "NONE"],
          ["ErrorMsg", theme.strong, theme.wash, "bold"],
          ["WarningMsg", theme.primary, theme.wash, "bold"],
          ["MoreMsg", theme.accent_secondary, "NONE", "NONE"],
          ["Question", theme.primary, "NONE", "NONE"],
          ["DiffAdd", theme.accent_secondary, theme.wash, "NONE"],
          ["DiffChange", theme.primary, theme.wash, "NONE"],
          ["DiffDelete", theme.strong, theme.wash, "strikethrough"],
          ["DiffText", theme.strong, theme.selection, "bold"],
          ["SpellBad", "NONE", "NONE", "undercurl", theme.strong],
          ["SpellCap", "NONE", "NONE", "undercurl", theme.primary],
          ["Comment", theme.muted, "NONE", "italic"],
          ["Constant", theme.fg, "NONE", "NONE"],
          ["String", theme.fg, "NONE", "NONE"],
          ["Identifier", theme.fg, "NONE", "NONE"],
          ["Function", theme.fg, "NONE", "bold"],
          ["Statement", theme.primary, "NONE", "NONE"],
          ["Operator", theme.secondary, "NONE", "NONE"],
          ["PreProc", theme.accent_secondary, "NONE", "NONE"],
          ["Type", theme.accent_secondary, "NONE", "NONE"],
          ["Special", theme.secondary, "NONE", "NONE"],
          ["Underlined", theme.primary, "NONE", "underline"],
          ["Ignore", theme.faint, "NONE", "NONE"],
          ["Error", theme.strong, theme.wash, "underline"],
          ["Todo", theme.primary, theme.wash, "bold"],
          ["DiagnosticError", theme.strong, "NONE", "bold"],
          ["DiagnosticWarn", theme.primary, "NONE", "bold"],
          ["DiagnosticInfo", theme.accent_secondary, "NONE", "NONE"],
          ["DiagnosticHint", theme.accent_faint, "NONE", "NONE"],
          ["DiagnosticUnderlineError", "NONE", "NONE", "undercurl", theme.strong],
          ["DiagnosticUnderlineWarn", "NONE", "NONE", "undercurl", theme.primary]
        ]
        commands = groups.map do |name, foreground, background, attributes, special|
          highlight(name, foreground, background, attributes, special)
        end.join("\n")
        links = {
          "lCursor" => "Cursor", "CursorIM" => "Cursor", "EndOfBuffer" => "NonText",
          "VertSplit" => "WinSeparator", "Character" => "String", "Number" => "Constant",
          "Boolean" => "Constant", "Float" => "Constant", "Conditional" => "Statement",
          "Repeat" => "Statement", "Label" => "Statement", "Keyword" => "Statement",
          "Exception" => "Statement", "Include" => "PreProc", "Define" => "PreProc",
          "Macro" => "PreProc", "StorageClass" => "Type", "Structure" => "Type",
          "Typedef" => "Type", "SpecialChar" => "Special", "Delimiter" => "Operator"
        }.map { |from, to| "highlight! link #{from} #{to}" }.join("\n")

        <<~VIM
          " Generated by Lacold #{Lacold::VERSION}. Do not edit.
          set background=#{theme.mode}
          highlight clear
          if exists('syntax_on')
            syntax reset
          endif
          let g:colors_name = '#{theme.id}'

          function! s:Hi(name, guifg, guibg, attr, guisp, ctermfg, ctermbg) abort
            execute 'highlight ' . a:name
                  \\ . ' guifg=' . a:guifg . ' guibg=' . a:guibg
                  \\ . ' gui=' . a:attr . ' guisp=' . a:guisp
                  \\ . ' ctermfg=' . a:ctermfg . ' ctermbg=' . a:ctermbg
                  \\ . ' cterm=' . a:attr . ' term=' . a:attr
          endfunction

          #{commands}

          #{links}

          delfunction s:Hi
        VIM
      end

      def highlight(name, foreground, background, attributes, special = "NONE")
        special ||= "NONE"
        cterm_fg = foreground == "NONE" ? "NONE" : Color.xterm_index(foreground)
        cterm_bg = background == "NONE" ? "NONE" : Color.xterm_index(background)
        "call s:Hi('#{name}', '#{foreground}', '#{background}', '#{attributes}', '#{special}', '#{cterm_fg}', '#{cterm_bg}')"
      end
    end
  end
end
