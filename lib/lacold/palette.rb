# frozen_string_literal: true

module Lacold
  class Palette
    NEUTRAL_ROLES = %i[
      bg surface raised line border fg secondary muted faint line_nr
      line_nr_active whitespace
    ].freeze
    ACCENT_ROLES = %i[
      strong primary secondary faint wash selection inactive_selection bracket
    ].freeze

    attr_reader :background, :color, :mode, :neutrals, :accent

    def initialize(background:, color:, mode:, neutrals:, accent:)
      @background = background.to_s.downcase
      @color = color.to_s.downcase
      @mode = mode.to_sym
      @neutrals = symbolize(neutrals).freeze
      @accent = symbolize(accent).freeze
      validate!
      freeze
    end

    def [](role)
      neutrals.fetch(role) { accent.fetch(role) }
    end

    def dark?
      mode == :dark
    end

    def id
      "lacold-#{background}-#{color}-#{mode}"
    end

    def name
      "Lacold #{background.capitalize} #{color.capitalize} #{mode.to_s.capitalize}"
    end

    def to_h
      {
        "id" => id,
        "name" => name,
        "background" => background,
        "color" => color,
        "mode" => mode.to_s,
        "neutrals" => stringify(neutrals),
        "accent" => stringify(accent)
      }
    end

    private

    def symbolize(values)
      values.to_h.transform_keys(&:to_sym)
    end

    def stringify(values)
      values.to_h.transform_keys(&:to_s)
    end

    def validate!
      raise Error, "mode must be light or dark" unless %i[light dark].include?(mode)

      validate_roles!(NEUTRAL_ROLES, neutrals, "neutral")
      validate_roles!(ACCENT_ROLES, accent, "accent")
    end

    def validate_roles!(required, values, kind)
      missing = required - values.keys
      extra = values.keys - required
      raise Error, "missing #{kind} roles: #{missing.join(', ')}" unless missing.empty?
      raise Error, "unknown #{kind} roles: #{extra.join(', ')}" unless extra.empty?

      invalid = values.reject { |_role, value| Color.valid?(value) }
      raise Error, "invalid #{kind} colors: #{invalid.inspect}" unless invalid.empty?
    end
  end
end

