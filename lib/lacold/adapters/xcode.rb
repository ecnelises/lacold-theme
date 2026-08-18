# frozen_string_literal: true

module Lacold
  module Adapters
    class Xcode < Base
      SYNTAX_KEYS = %w[
        xcode.syntax.attribute xcode.syntax.character xcode.syntax.comment
        xcode.syntax.comment.doc xcode.syntax.comment.doc.keyword
        xcode.syntax.declaration.other xcode.syntax.declaration.type
        xcode.syntax.identifier.class xcode.syntax.identifier.class.system
        xcode.syntax.identifier.constant xcode.syntax.identifier.constant.system
        xcode.syntax.identifier.function xcode.syntax.identifier.function.system
        xcode.syntax.identifier.macro xcode.syntax.identifier.macro.system
        xcode.syntax.identifier.type xcode.syntax.identifier.type.system
        xcode.syntax.identifier.variable xcode.syntax.identifier.variable.system
        xcode.syntax.keyword xcode.syntax.mark xcode.syntax.markup.code
        xcode.syntax.number xcode.syntax.plain xcode.syntax.preprocessor
        xcode.syntax.string xcode.syntax.url xcode.syntax.markup.aside.kind
      ].freeze

      def id = "xcode"
      def name = "Xcode"
      def description = "Xcode .xccolortheme files"

      def render(themes)
        files = themes.map { |theme| output("xcode/#{theme.id}.xccolortheme", xcode_theme(theme)) }
        files << target_readme
      end

      private

      def xcode_theme(theme)
        syntax = SYNTAX_KEYS.map do |key|
          value = case key
                  when /comment/ then theme.muted
                  when /attribute/ then theme.syntax_color(:attribute, theme.primary)
                  when /macro/ then theme.syntax_color(:macro, theme.accent_secondary)
                  when /preprocessor/ then theme.syntax_color(:preprocessor, theme.accent_secondary)
                  when /type|class/ then theme.syntax_color(:type, theme.accent_secondary)
                  when /function/ then theme.syntax_color(:function, theme.fg)
                  when /string|character/ then theme.syntax_color(:string, theme.fg)
                  when /constant/ then theme.syntax_color(:constant, theme.fg)
                  when /number/ then theme.syntax_color(:number, theme.accent_secondary)
                  when /keyword|declaration/ then theme.syntax_color(:keyword, theme.primary)
                  when /url/ then theme.syntax_color(:link, theme.primary)
                  when /aside/ then theme.syntax_color(:type, theme.accent_secondary)
                  when /mark/ then theme.secondary
                  else theme.fg
                  end
          "        <key>#{key}</key>\n        <string>#{rgba_unit(value)}</string>"
        end.join("\n")
        fonts = SYNTAX_KEYS.map do |key|
          weight = key.match?(/keyword|mark/) ? "SFMono-Semibold" : "SFMono-Regular"
          "        <key>#{key}</key>\n        <string>#{weight} - 12.0</string>"
        end.join("\n")
        body = <<~BODY
          <dict>
            <key>DVTConsoleDebuggerInputTextColor</key><string>#{rgba_unit(theme.fg)}</string>
            <key>DVTConsoleDebuggerInputTextFont</key><string>SFMono-Regular - 12.0</string>
            <key>DVTConsoleDebuggerOutputTextColor</key><string>#{rgba_unit(theme.fg)}</string>
            <key>DVTConsoleDebuggerOutputTextFont</key><string>SFMono-Regular - 12.0</string>
            <key>DVTConsoleDebuggerPromptTextColor</key><string>#{rgba_unit(theme.primary)}</string>
            <key>DVTConsoleDebuggerPromptTextFont</key><string>SFMono-Regular - 12.0</string>
            <key>DVTConsoleExectuableInputTextColor</key><string>#{rgba_unit(theme.fg)}</string>
            <key>DVTConsoleExectuableInputTextFont</key><string>SFMono-Regular - 12.0</string>
            <key>DVTConsoleExectuableOutputTextColor</key><string>#{rgba_unit(theme.fg)}</string>
            <key>DVTConsoleExectuableOutputTextFont</key><string>SFMono-Regular - 12.0</string>
            <key>DVTConsoleTextBackgroundColor</key><string>#{rgba_unit(theme.bg)}</string>
            <key>DVTConsoleTextSelectionColor</key><string>#{rgba_unit(theme.selection)}</string>
            <key>DVTFontAndColorVersion</key><integer>1</integer>
            <key>DVTLineSpacing</key><real>1.1</real>
            <key>DVTScrollbarMarkerAnalyzerColor</key><string>#{rgba_unit(theme.accent_secondary)}</string>
            <key>DVTScrollbarMarkerBreakpointColor</key><string>#{rgba_unit(theme.primary)}</string>
            <key>DVTScrollbarMarkerDiffColor</key><string>#{rgba_unit(theme.accent_faint)}</string>
            <key>DVTScrollbarMarkerDiffConflictColor</key><string>#{rgba_unit(theme.strong)}</string>
            <key>DVTScrollbarMarkerErrorColor</key><string>#{rgba_unit(theme.strong)}</string>
            <key>DVTScrollbarMarkerRuntimeIssueColor</key><string>#{rgba_unit(theme.accent_secondary)}</string>
            <key>DVTScrollbarMarkerWarningColor</key><string>#{rgba_unit(theme.accent_secondary)}</string>
            <key>DVTSourceTextBackground</key><string>#{rgba_unit(theme.bg)}</string>
            <key>DVTSourceTextCurrentLineHighlightColor</key><string>#{rgba_unit(theme.line)}</string>
            <key>DVTSourceTextInvisiblesColor</key><string>#{rgba_unit(theme.whitespace)}</string>
            <key>DVTSourceTextSelectionColor</key><string>#{rgba_unit(theme.selection)}</string>
            <key>DVTSourceTextSyntaxColors</key>
            <dict>
          #{syntax}
            </dict>
            <key>DVTSourceTextSyntaxFonts</key>
            <dict>
          #{fonts}
            </dict>
          </dict>
        BODY
        plist_document(body)
      end
    end
  end
end
