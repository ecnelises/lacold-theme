# frozen_string_literal: true

module Lacold
  module Color
    HEX = /\A#[0-9A-F]{6}\z/

    module_function

    def valid?(value)
      value.is_a?(String) && HEX.match?(value)
    end

    def rgb(value)
      raise ArgumentError, "invalid color: #{value.inspect}" unless valid?(value)

      value.delete_prefix("#").scan(/../).map { |part| part.to_i(16) }
    end

    def components(value)
      rgb(value).map { |component| (component / 255.0).round(6) }
    end

    def luminance(value)
      channels = components(value).map do |component|
        component <= 0.04045 ? component / 12.92 : ((component + 0.055) / 1.055)**2.4
      end
      (0.2126 * channels[0]) + (0.7152 * channels[1]) + (0.0722 * channels[2])
    end

    def contrast(first, second)
      light, dark = [luminance(first), luminance(second)].sort.reverse
      (light + 0.05) / (dark + 0.05)
    end

    # Nearest xterm-256 entry. This maps an authored color; it never changes the
    # true-color palette used by capable terminals.
    def xterm_index(value)
      target = rgb(value)
      candidates = xterm_candidates
      candidates.min_by do |_index, candidate|
        target.zip(candidate).sum { |left, right| (left - right)**2 }
      end.first
    end

    def css_rgba(value, alpha)
      red, green, blue = rgb(value)
      "rgba(#{red}, #{green}, #{blue}, #{alpha})"
    end

    def xterm_candidates
      @xterm_candidates ||= begin
        values = [0, 95, 135, 175, 215, 255]
        cube = {}
        6.times do |red|
          6.times do |green|
            6.times do |blue|
              cube[16 + (36 * red) + (6 * green) + blue] = [values[red], values[green], values[blue]]
            end
          end
        end
        gray = (0..23).to_h { |step| [232 + step, [8 + (step * 10)] * 3] }
        cube.merge(gray).freeze
      end
    end
    private_class_method :xterm_candidates
  end
end

