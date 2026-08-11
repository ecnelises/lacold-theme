# frozen_string_literal: true

module Lacold
  module Adapters
    module TextMate
      private

      def textmate(theme, uuid: nil)
        global = {
          "background" => theme.bg,
          "caret" => theme.primary,
          "foreground" => theme.fg,
          "invisibles" => theme.whitespace,
          "lineHighlight" => theme.line,
          "selection" => theme.selection
        }
        entries = [settings_entry(nil, nil, global)] + theme.textmate_settings.map do |name, scopes, foreground, style|
          values = {"foreground" => foreground}
          values["fontStyle"] = style if style
          settings_entry(name, scopes.join(", "), values)
        end
        uuid_xml = uuid ? "\n  <key>uuid</key>\n  <string>#{xml(uuid)}</string>" : ""
        plist_document(<<~XML)
          <dict>
            <key>name</key>
            <string>#{xml(theme.name)}</string>#{uuid_xml}
            <key>settings</key>
            <array>
          #{entries.join("\n")}
            </array>
          </dict>
        XML
      end

      def settings_entry(name, scope, values)
        name_xml = name ? "\n      <key>name</key>\n      <string>#{xml(name)}</string>" : ""
        scope_xml = scope ? "\n      <key>scope</key>\n      <string>#{xml(scope)}</string>" : ""
        settings = values.map do |key, value|
          "        <key>#{xml(key)}</key>\n        <string>#{xml(value)}</string>"
        end.join("\n")
        <<~XML.chomp
              <dict>#{name_xml}#{scope_xml}
                <key>settings</key>
                <dict>
          #{settings}
                </dict>
              </dict>
        XML
      end
    end
  end
end

