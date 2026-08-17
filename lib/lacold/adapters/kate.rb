# frozen_string_literal: true

module Lacold
  module Adapters
    class Kate < Base
      TEXT_STYLES = %w[
        Normal Keyword Function Variable ControlFlow Operator BuiltIn Extension
        Preprocessor Attribute Char SpecialChar String VerbatimString SpecialString
        Import DataType DecVal BaseN Float Constant Comment Documentation Annotation
        CommentVar RegionMarker Information Warning Alert Error Others
      ].freeze

      def id = "kate"
      def name = "Kate"
      def description = "Kate and KSyntaxHighlighting themes"

      def render(themes)
        files = themes.map { |theme| output("kate/#{theme.id}.theme", json(kate_theme(theme))) }
        files << output("kate/README.md", <<~MARKDOWN)
          # Lacold for Kate

          Copy `.theme` files into `~/.local/share/org.kde.syntax-highlighting/themes/`,
          restart Kate, and select the theme under Editor → Fonts & Colors.
        MARKDOWN
      end

      private

      def kate_theme(theme)
        text_styles = TEXT_STYLES.to_h do |name|
          foreground = case name
                       when "Comment", "Documentation", "CommentVar" then theme.muted
                       when "Keyword", "ControlFlow", "Import" then theme.syntax_color(:keyword, theme.primary)
                       when "Preprocessor" then theme.syntax_color(:preprocessor, theme.primary)
                       when "Attribute", "Annotation" then theme.syntax_color(:attribute, theme.primary)
                       when "DataType", "BuiltIn", "Extension" then theme.syntax_color(:type, theme.accent_secondary)
                       when "Function" then theme.syntax_color(:function, theme.fg)
                       when "Char", "SpecialChar", "String", "VerbatimString", "SpecialString" then theme.syntax_color(:string, theme.fg)
                       when "DecVal", "BaseN", "Float" then theme.syntax_color(:number, theme.accent_secondary)
                       when "Constant" then theme.syntax_color(:constant, theme.fg)
                       when "Operator" then theme.syntax_color(:operator, theme.fg)
                       when "Warning", "Alert", "Error" then theme.strong
                       else theme.fg
                       end
          style = {"text-color" => foreground, "selected-text-color" => theme.fg}
          style["bold"] = true if %w[Keyword ControlFlow BuiltIn Alert].include?(name)
          style["italic"] = true if %w[Comment Documentation].include?(name)
          style["underline"] = true if name == "Error"
          style["background-color"] = theme.wash if %w[RegionMarker Alert].include?(name)
          [name, style]
        end
        {
          "metadata" => {
            "copyright" => ["SPDX-FileCopyrightText: Lacold contributors"],
            "license" => "SPDX-License-Identifier: MIT", "revision" => 1,
            "name" => theme.name
          },
          "text-styles" => text_styles,
          "custom-styles" => {},
          "editor-colors" => {
            "BackgroundColor" => theme.bg, "CodeFolding" => theme.accent_faint,
            "BracketMatching" => theme.bracket, "CurrentLine" => theme.line,
            "IconBorder" => theme.surface, "IndentationLine" => theme.border,
            "LineNumbers" => theme.line_nr, "CurrentLineNumber" => theme.line_nr_active,
            "MarkBookmark" => theme.primary, "MarkBreakpointActive" => theme.strong,
            "MarkBreakpointReached" => theme.primary, "MarkBreakpointDisabled" => theme.muted,
            "MarkExecution" => theme.accent_secondary, "MarkWarning" => theme.accent_secondary,
            "MarkError" => theme.strong, "ModifiedLines" => theme.accent_secondary,
            "ReplaceHighlight" => theme.selection, "SavedLines" => theme.primary,
            "SearchHighlight" => theme.wash, "TextSelection" => theme.selection,
            "Separator" => theme.border, "SpellChecking" => theme.strong,
            "TabMarker" => theme.whitespace, "TemplateBackground" => theme.surface,
            "TemplatePlaceholder" => theme.wash, "TemplateFocusedPlaceholder" => theme.selection,
            "TemplateReadOnlyPlaceholder" => theme.inactive_selection,
            "WordWrapMarker" => theme.line
          }
        }
      end
    end
  end
end
