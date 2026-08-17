# frozen_string_literal: true

module Lacold
  module Adapters
    class Gedit < Base
      def id = "gedit"
      def name = "Gedit"
      def description = "GtkSourceView style schemes for Gedit"

      def render(themes)
        files = themes.map { |theme| output("gedit/#{theme.id}.xml", gedit_theme(theme)) }
        files << output("gedit/README.md", <<~MARKDOWN)
          # Lacold for Gedit

          Copy XML files to `~/.local/share/gtksourceview-5/styles/` (or the
          matching GtkSourceView version's `styles` directory), restart Gedit,
          and select the scheme in preferences.
        MARKDOWN
      end

      private

      def gedit_theme(theme)
        <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <style-scheme id="#{theme.id}" name="#{xml(theme.name)}" version="1.0">
            <author>Lacold contributors</author>
            <description>Neutral foundation with restrained authored accents.</description>
            <metadata><property name="variant">#{theme.mode}</property></metadata>
            <color name="background" value="#{theme.bg}"/>
            <color name="foreground" value="#{theme.fg}"/>
            <color name="surface" value="#{theme.surface}"/>
            <color name="line" value="#{theme.line}"/>
            <color name="selection" value="#{theme.selection}"/>
            <color name="accent" value="#{theme.primary}"/>
            <color name="accent-secondary" value="#{theme.accent_secondary}"/>
            <color name="muted" value="#{theme.muted}"/>
            <style name="text" foreground="foreground" background="background"/>
            <style name="selection" foreground="foreground" background="selection"/>
            <style name="cursor" foreground="accent"/>
            <style name="current-line" background="line"/>
            <style name="line-numbers" foreground="#{theme.line_nr}" background="background"/>
            <style name="current-line-number" foreground="#{theme.line_nr_active}" background="line" bold="true"/>
            <style name="draw-spaces" foreground="#{theme.whitespace}"/>
            <style name="right-margin" foreground="#{theme.border}" background="background"/>
            <style name="def:comment" foreground="muted" italic="true"/>
            <style name="def:keyword" foreground="#{theme.syntax_color(:keyword, theme.primary)}"/>
            <style name="def:type" foreground="#{theme.syntax_color(:type, theme.accent_secondary)}"/>
            <style name="def:function" foreground="#{theme.syntax_color(:function, theme.fg)}" bold="true"/>
            <style name="def:string" foreground="#{theme.syntax_color(:string, theme.fg)}"/>
            <style name="def:number" foreground="#{theme.syntax_color(:number, theme.accent_secondary)}"/>
            <style name="def:constant" foreground="#{theme.syntax_color(:constant, theme.fg)}"/>
            <style name="def:preprocessor" foreground="#{theme.syntax_color(:preprocessor, theme.primary)}"/>
            <style name="def:error" foreground="#{theme.red}" underline="error"/>
            <style name="def:warning" foreground="#{theme.orange}" bold="true"/>
          </style-scheme>
        XML
      end
    end
  end
end
