# frozen_string_literal: true

module Lacold
  module Adapters
    class GnomeTerminal < Base
      def id = "gnome-terminal"
      def name = "GNOME Terminal"
      def description = "GNOME Terminal dconf profile values"

      def render(themes)
        files = themes.map { |theme| output("gnome-terminal/#{theme.id}.dconf", dconf(theme)) }
        files << target_readme
      end

      private

      def dconf(theme)
        palette = theme.ansi.values.map { |color| "'#{color}'" }.join(", ")
        <<~DCONF
          [/]
          visible-name='#{theme.name}'
          use-theme-colors=false
          background-color='#{theme.bg}'
          foreground-color='#{theme.fg}'
          bold-color-same-as-fg=true
          cursor-colors-set=true
          cursor-background-color='#{theme.primary}'
          cursor-foreground-color='#{theme.bg}'
          highlight-colors-set=true
          highlight-background-color='#{theme.selection}'
          highlight-foreground-color='#{theme.fg}'
          palette=[#{palette}]
          use-theme-transparency=false
        DCONF
      end
    end
  end
end
