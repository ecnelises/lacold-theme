# frozen_string_literal: true

module Lacold
  class Registry
    attr_reader :backgrounds, :accents

    def initialize
      @backgrounds = {}
      @accents = {}
    end

    def register_background(name, light:, dark:)
      backgrounds[normalize(name)] = {light: symbolize(light), dark: symbolize(dark)}.freeze
      self
    end

    def register_accent(name, light:, dark:)
      accents[normalize(name)] = {light: symbolize(light), dark: symbolize(dark)}.freeze
      self
    end

    def colors
      accents.keys.sort
    end

    def modes
      %i[light dark]
    end

    def themes(backgrounds: self.backgrounds.keys, colors: self.colors, modes: self.modes)
      backgrounds = Array(backgrounds).map { |value| normalize(value) }
      colors = Array(colors).map { |value| normalize(value) }
      modes = Array(modes).map { |value| value.to_s.downcase.to_sym }

      validate_selection!(backgrounds, self.backgrounds.keys, "background")
      validate_selection!(colors, self.colors, "color")
      validate_selection!(modes, self.modes, "mode")

      backgrounds.product(colors, modes).map do |background, color, mode|
        Theme.new(Palette.new(
          background: background,
          color: color,
          mode: mode,
          neutrals: self.backgrounds.fetch(background).fetch(mode),
          accent: accents.fetch(color).fetch(mode)
        ))
      end
    end

    private

    def normalize(value)
      value.to_s.downcase
    end

    def symbolize(values)
      values.to_h.transform_keys(&:to_sym).freeze
    end

    def validate_selection!(selected, available, kind)
      unknown = selected - available
      return if unknown.empty?

      raise Error, "unknown #{kind}: #{unknown.join(', ')} (available: #{available.join(', ')})"
    end
  end
end

