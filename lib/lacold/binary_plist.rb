# frozen_string_literal: true

module Lacold
  # Minimal binary-property-list writer used for NSColor keyed archives in
  # Terminal.app profiles. It intentionally implements only the object types
  # needed here.
  module BinaryPlist
    UID = Data.define(:value)
    Blob = Data.define(:value)

    module_function

    def dump(root)
      encoder = Encoder.new
      encoder.dump(root)
    end

    def keyed_color(hex)
      red, green, blue = Color.components(hex)
      rgb = [red, green, blue].map { |value| format("%.6f", value).sub(/0+\z/, "").sub(/\.\z/, "") }.join(" ")
      dump(
        "$version" => 100_000,
        "$archiver" => "NSKeyedArchiver",
        "$top" => {"root" => UID.new(1)},
        "$objects" => [
          "$null",
          {"NSRGB" => Blob.new(rgb), "NSColorSpace" => 1, "$class" => UID.new(2)},
          {"$classname" => "NSColor", "$classes" => ["NSColor", "NSObject"]}
        ]
      )
    end

    class Encoder
      def initialize
        @objects = []
        @index = {}
      end

      def dump(root)
        top = intern(root)
        reference_size = integer_size(@objects.length - 1)
        encoded = @objects.map { |object| encode(object, reference_size) }
        offsets = []
        cursor = 8
        encoded.each do |value|
          offsets << cursor
          cursor += value.bytesize
        end
        offset_size = integer_size(cursor)
        offset_table = offsets.map { |offset| pack_integer(offset, offset_size) }.join
        trailer = ("\0" * 6) + [offset_size, reference_size].pack("CC") +
          [@objects.length, top, cursor].pack("Q>Q>Q>")
        "bplist00" + encoded.join + offset_table + trailer
      end

      private

      def intern(object)
        key = case object
              when Hash, Array then [object.class, object.object_id]
              when UID then [UID, object.value, object.object_id]
              when Blob then [Blob, object.value, object.object_id]
              else [object.class, object]
              end
        return @index.fetch(key) if @index.key?(key)

        index = @objects.length
        @index[key] = index
        @objects << nil
        @objects[index] = case object
                          when Hash
                            [:dict, object.keys.map { |item| intern(item.to_s) }, object.values.map { |item| intern(item) }]
                          when Array
                            [:array, object.map { |item| intern(item) }]
                          when UID
                            [:uid, object.value]
                          when Blob
                            [:data, object.value.b]
                          when Integer
                            [:integer, object]
                          when String
                            [:string, object]
                          when true, false
                            [:boolean, object]
                          else
                            raise ArgumentError, "unsupported plist object: #{object.class}"
                          end
        index
      end

      def encode(object, reference_size)
        type, *values = object
        case type
        when :dict
          keys, items = values
          marker(keys.length, 0xD0) + pack_references(keys + items, reference_size)
        when :array
          items = values.first
          marker(items.length, 0xA0) + pack_references(items, reference_size)
        when :uid
          value = values.first
          size = integer_size(value)
          [(0x80 | (size - 1))].pack("C") + pack_integer(value, size)
        when :data
          value = values.first
          marker(value.bytesize, 0x40) + value
        when :integer
          value = values.first
          size = integer_size(value)
          exponent = Math.log2(size).to_i
          [(0x10 | exponent)].pack("C") + pack_integer(value, size)
        when :string
          value = values.first.b
          marker(value.bytesize, 0x50) + value
        when :boolean
          [values.first ? 0x09 : 0x08].pack("C")
        end
      end

      def marker(length, base)
        return [(base | length)].pack("C") if length < 15

        size = integer_size(length)
        exponent = Math.log2(size).to_i
        [base | 15, 0x10 | exponent].pack("CC") + pack_integer(length, size)
      end

      def pack_references(references, size)
        references.map { |reference| pack_integer(reference, size) }.join
      end

      def integer_size(value)
        return 1 if value <= 0xFF
        return 2 if value <= 0xFFFF
        return 4 if value <= 0xFFFFFFFF

        8
      end

      def pack_integer(value, size)
        case size
        when 1 then [value].pack("C")
        when 2 then [value].pack("n")
        when 4 then [value].pack("N")
        when 8 then [value].pack("Q>")
        end
      end
    end
  end
end
