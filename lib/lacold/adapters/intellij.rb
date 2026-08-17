# frozen_string_literal: true

module Lacold
  module Adapters
    class IntelliJ < Base
      def id = "intellij"
      def name = "IntelliJ Platform"
      def description = "JetBrains editor color schemes"

      def render(themes)
        files = themes.map { |theme| output("intellij/#{theme.id}.icls", intellij_theme(theme)) }
        files << output("intellij/README.md", <<~MARKDOWN)
          # Lacold for IntelliJ Platform

          In a JetBrains IDE, open Settings → Editor → Color Scheme, use the
          gear menu to import a scheme, and choose the `.icls` file.
        MARKDOWN
      end

      private

      def attribute(name, foreground:, background: nil, effect: nil, font_type: nil)
        options = ["<option name=\"FOREGROUND\" value=\"#{bare(foreground)}\" />"]
        options << "<option name=\"BACKGROUND\" value=\"#{bare(background)}\" />" if background
        if effect
          options << "<option name=\"EFFECT_COLOR\" value=\"#{bare(effect)}\" />"
          options << "<option name=\"EFFECT_TYPE\" value=\"1\" />"
        end
        options << "<option name=\"FONT_TYPE\" value=\"#{font_type}\" />" if font_type
        "    <option name=\"#{name}\"><value>#{options.join}</value></option>"
      end

      def intellij_theme(theme)
        attrs = [
          attribute("TEXT", foreground: theme.fg, background: theme.bg),
          attribute("DEFAULT_KEYWORD", foreground: theme.syntax_color(:keyword, theme.primary), font_type: 1),
          attribute("DEFAULT_STRING", foreground: theme.syntax_color(:string, theme.fg)),
          attribute("DEFAULT_NUMBER", foreground: theme.syntax_color(:number, theme.accent_secondary)),
          attribute("DEFAULT_CONSTANT", foreground: theme.syntax_color(:constant, theme.fg)),
          attribute("DEFAULT_FUNCTION_DECLARATION", foreground: theme.syntax_color(:function, theme.fg), font_type: 1),
          attribute("DEFAULT_INSTANCE_FIELD", foreground: theme.syntax_color(:property, theme.fg)),
          attribute("DEFAULT_STATIC_FIELD", foreground: theme.syntax_color(:property, theme.fg)),
          attribute("DEFAULT_CLASS_NAME", foreground: theme.syntax_color(:type, theme.accent_secondary)),
          attribute("DEFAULT_METADATA", foreground: theme.syntax_color(:attribute, theme.accent_secondary)),
          attribute("DEFAULT_IDENTIFIER", foreground: theme.fg),
          attribute("DEFAULT_LINE_COMMENT", foreground: theme.muted, font_type: 2),
          attribute("DEFAULT_BLOCK_COMMENT", foreground: theme.muted, font_type: 2),
          attribute("DEFAULT_DOC_COMMENT", foreground: theme.muted, font_type: 2),
          attribute("DEFAULT_INVALID_STRING_ESCAPE", foreground: theme.strong, effect: theme.strong),
          attribute("ERRORS_ATTRIBUTES", foreground: theme.strong, effect: theme.strong),
          attribute("WARNING_ATTRIBUTES", foreground: theme.accent_secondary, effect: theme.accent_secondary)
        ].join("\n")
        <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <scheme name="#{xml(theme.name)}" version="142" parent_scheme="Default">
            <metaInfo><property name="created">Lacold #{Lacold::VERSION}</property></metaInfo>
            <option name="LINE_SPACING" value="1.1" />
            <option name="EDITOR_FONT_SIZE" value="13" />
            <colors>
              <option name="CARET_COLOR" value="#{bare(theme.primary)}" />
              <option name="CARET_ROW_COLOR" value="#{bare(theme.line)}" />
              <option name="GUTTER_BACKGROUND" value="#{bare(theme.bg)}" />
              <option name="LINE_NUMBERS_COLOR" value="#{bare(theme.line_nr)}" />
              <option name="SELECTED_TEXT_BACKGROUND" value="#{bare(theme.selection)}" />
              <option name="SELECTION_BACKGROUND" value="#{bare(theme.selection)}" />
              <option name="WHITESPACES" value="#{bare(theme.whitespace)}" />
            </colors>
            <attributes>
          #{attrs}
            </attributes>
          </scheme>
        XML
      end
    end
  end
end
