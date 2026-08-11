# frozen_string_literal: true

module Lacold
  module Adapters
    class VisualStudio < Base
      TEXT_MANAGER_CATEGORY = "{58E96763-1D3B-4E05-B6BA-FF7115FD0B7B}"
      LANGUAGE_SERVICE_CATEGORY = "{E0187991-B458-4F7E-8CA9-42C9A573B56C}"
      TEXT_MARKER_CATEGORY = "{FF349800-EA43-46C1-8C98-878E78F46501}"

      def id = "visual-studio"
      def name = "Visual Studio"
      def description = "Visual Studio Color Theme Designer files"

      def render(themes)
        files = themes.map { |theme| output("visual-studio/#{theme.id}.vstheme", visual_studio_theme(theme)) }
        files << output("visual-studio/README.md", <<~MARKDOWN)
          # Lacold for Visual Studio

          Install Microsoft's Color Theme Designer extension, then import the
          selected `.vstheme` file. These themes use the same single-hue state
          mapping as every other Lacold carrier.
        MARKDOWN
      end

      private

      def raw(color)
        "FF#{bare(color).upcase}"
      end

      def vs_color(name, foreground: nil, background: nil, transparent_foreground: false, transparent_background: false)
        values = []
        values << "<Foreground Type=\"CT_INVALID\" Source=\"00000000\" />" if transparent_foreground
        values << "<Background Type=\"CT_INVALID\" Source=\"00000000\" />" if transparent_background
        values << "<Foreground Type=\"CT_RAW\" Source=\"#{raw(foreground)}\" />" if foreground
        values << "<Background Type=\"CT_RAW\" Source=\"#{raw(background)}\" />" if background
        "      <Color Name=\"#{xml(name)}\">#{values.join}</Color>"
      end

      def visual_studio_theme(theme)
        manager_colors = [
          vs_color("Plain Text", foreground: theme.fg, background: theme.bg),
          vs_color("Selected Text", foreground: theme.fg, background: theme.selection),
          vs_color("Inactive Selected Text", foreground: theme.fg, background: theme.inactive_selection),
          vs_color("Visible Whitespace", foreground: theme.whitespace, transparent_background: true)
        ].join("\n")
        language_colors = [
          vs_color("Keyword", foreground: theme.primary, transparent_background: true),
          vs_color("Comment", foreground: theme.muted, transparent_background: true),
          vs_color("String", foreground: theme.fg, transparent_background: true),
          vs_color("Number", foreground: theme.accent_secondary, transparent_background: true),
          vs_color("User Types", foreground: theme.accent_secondary, transparent_background: true),
          vs_color("Identifier", foreground: theme.fg, transparent_background: true),
          vs_color("Preprocessor Keyword", foreground: theme.primary, transparent_background: true),
          vs_color("Operator", foreground: theme.secondary, transparent_background: true),
          vs_color("Line Number", foreground: theme.line_nr, transparent_background: true),
          vs_color("URL Hyperlink", foreground: theme.primary, transparent_background: true)
        ].join("\n")
        marker_colors = [
          vs_color("Current Statement", transparent_foreground: true, background: theme.line),
          vs_color("Brace Matching (Rectangle)", transparent_foreground: true, background: theme.bracket),
          vs_color("Syntax Error", foreground: theme.strong, transparent_background: true),
          vs_color("Warning", foreground: theme.accent_secondary, transparent_background: true)
        ].join("\n")
        <<~XML
          <?xml version="1.0" encoding="utf-8"?>
          <Themes>
            <Theme Name="#{xml(theme.name)}" GUID="{#{stable_uuid(theme.id).upcase}}">
              <Category Name="Text Editor Text Manager Items" GUID="#{TEXT_MANAGER_CATEGORY}">
          #{manager_colors}
              </Category>
              <Category Name="Text Editor Language Service Items" GUID="#{LANGUAGE_SERVICE_CATEGORY}">
          #{language_colors}
              </Category>
              <Category Name="Text Editor Text Marker Items" GUID="#{TEXT_MARKER_CATEGORY}">
          #{marker_colors}
              </Category>
            </Theme>
          </Themes>
        XML
      end
    end
  end
end
