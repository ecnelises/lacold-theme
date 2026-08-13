# frozen_string_literal: true

require "json"
require "digest"

module Lacold
  module Adapters
    Output = Data.define(:path, :content)

    class Base
      def id
        raise NotImplementedError
      end

      def name
        id.split("-").map(&:capitalize).join(" ")
      end

      def kind
        "native"
      end

      def description
        "Native theme files"
      end

      def render(_themes)
        raise NotImplementedError
      end

      private

      def output(path, content)
        Output.new(path, content.end_with?("\n") ? content : "#{content}\n")
      end

      def json(value)
        "#{JSON.pretty_generate(value)}\n"
      end

      def xml(value)
        value.to_s
          .gsub("&", "&amp;")
          .gsub("<", "&lt;")
          .gsub(">", "&gt;")
          .gsub('"', "&quot;")
          .gsub("'", "&apos;")
      end

      def plist_document(body)
        <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
          <plist version="1.0">
          #{body}
          </plist>
        XML
      end

      def plist_color_components(hex)
        red, green, blue = Color.components(hex)
        <<~XML.chomp
          <dict>
            <key>Alpha Component</key>
            <real>1</real>
            <key>Blue Component</key>
            <real>#{blue}</real>
            <key>Color Space</key>
            <string>sRGB</string>
            <key>Green Component</key>
            <real>#{green}</real>
            <key>Red Component</key>
            <real>#{red}</real>
          </dict>
        XML
      end

      def bare(hex)
        hex.delete_prefix("#")
      end

      def rgb_line(hex, separator = " ")
        Color.rgb(hex).join(separator)
      end

      def rgba_unit(hex)
        Color.components(hex).map { |component| format("%.6f", component) }.join(" ") + " 1"
      end

      def stable_uuid(value)
        hex = Digest::SHA256.hexdigest("lacold:#{value}")[0, 32]
        hex[12] = "4"
        hex[16] = ((hex[16].to_i(16) & 3) | 8).to_s(16)
        [hex[0, 8], hex[8, 4], hex[12, 4], hex[16, 4], hex[20, 12]].join("-")
      end
    end
  end
end
