# frozen_string_literal: true

module Lacold
  module Adapters
    class Zed < Base
      def id = "zed"
      def name = "Zed"
      def description = "Zed theme family JSON files"

      def render(themes)
        files = themes.map { |theme| output("zed/#{theme.id}.json", json(zed_theme(theme))) }
        files << target_readme
      end

      private

      def zed_theme(theme)
        ansi = theme.ansi
        syntax = {
          "comment" => {"color" => theme.muted, "font_style" => "italic"},
          "keyword" => {"color" => theme.syntax_color(:keyword, theme.primary)},
          "type" => {"color" => theme.syntax_color(:type, theme.accent_secondary)},
          "function" => {"color" => theme.syntax_color(:function, theme.fg), "font_weight" => 700},
          "string" => {"color" => theme.syntax_color(:string, theme.fg)},
          "number" => {"color" => theme.syntax_color(:number, theme.accent_secondary)},
          "constant" => {"color" => theme.syntax_color(:constant, theme.fg)},
          "variable" => {"color" => theme.syntax_color(:variable, theme.fg)},
          "property" => {"color" => theme.syntax_color(:property, theme.fg)},
          "operator" => {"color" => theme.syntax_color(:operator, theme.secondary)},
          "punctuation" => {"color" => theme.syntax_color(:punctuation, theme.secondary)},
          "attribute" => {"color" => theme.syntax_color(:attribute, theme.accent_secondary)},
          "link_uri" => {"color" => theme.syntax_color(:link, theme.primary)}
        }
        style = {
          "border" => theme.border, "border.variant" => theme.line,
          "border.focused" => theme.primary, "border.selected" => theme.primary,
          "elevated_surface.background" => theme.raised, "surface.background" => theme.surface,
          "background" => theme.bg, "element.background" => theme.surface,
          "element.hover" => theme.raised, "element.active" => theme.selection,
          "element.selected" => theme.selection, "drop_target.background" => theme.wash,
          "text" => theme.fg, "text.muted" => theme.muted,
          "text.placeholder" => theme.faint, "text.disabled" => theme.faint,
          "text.accent" => theme.primary, "icon" => theme.fg,
          "icon.muted" => theme.muted, "icon.disabled" => theme.faint,
          "icon.accent" => theme.primary, "status_bar.background" => theme.surface,
          "title_bar.background" => theme.surface, "title_bar.inactive_background" => theme.bg,
          "toolbar.background" => theme.surface, "tab_bar.background" => theme.surface,
          "tab.inactive_background" => theme.surface, "tab.active_background" => theme.bg,
          "search.match_background" => theme.wash, "search.active_match_background" => theme.selection,
          "panel.background" => theme.surface, "editor.foreground" => theme.fg,
          "editor.background" => theme.bg, "editor.gutter.background" => theme.bg,
          "editor.subheader.background" => theme.surface, "editor.active_line.background" => theme.line,
          "editor.highlighted_line.background" => theme.line,
          "editor.line_number" => theme.line_nr, "editor.active_line_number" => theme.line_nr_active,
          "editor.hover_line_number" => theme.secondary, "editor.invisible" => theme.whitespace,
          "terminal.background" => theme.bg, "terminal.foreground" => theme.fg,
          "terminal.bright_foreground" => ansi[:bright_white], "terminal.dim_foreground" => theme.muted,
          "link_text.hover" => theme.primary, "version_control.added" => theme.green,
          "version_control.modified" => theme.primary, "version_control.deleted" => theme.red,
          "error" => theme.red, "error.background" => theme.red_wash,
          "warning" => theme.orange, "warning.background" => theme.orange_wash,
          "success" => theme.green, "success.background" => theme.green_wash,
          "info" => theme.accent_faint, "info.background" => theme.wash,
          "conflict" => theme.orange, "created" => theme.green,
          "deleted" => theme.red, "modified" => theme.primary,
          "renamed" => theme.primary, "hint" => theme.accent_faint,
          "players" => [{"cursor" => theme.primary, "background" => theme.primary, "selection" => theme.selection}],
          "syntax" => syntax
        }
        normal_names = %i[black red green yellow blue magenta cyan white]
        bright_names = %i[bright_black bright_red bright_green bright_yellow bright_blue bright_magenta bright_cyan bright_white]
        normal_names.each { |name| style["terminal.ansi.#{name}"] = ansi[name] }
        bright_names.each { |name| style["terminal.ansi.#{name}"] = ansi[name] }
        {
          "$schema" => "https://zed.dev/schema/themes/v0.2.0.json",
          "name" => theme.name, "author" => "Lacold contributors",
          "themes" => [{"name" => theme.name, "appearance" => theme.mode.to_s, "style" => style}]
        }
      end
    end
  end
end
