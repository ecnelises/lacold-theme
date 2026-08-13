# frozen_string_literal: true

module Lacold
  class Validator
    attr_reader :adapters

    def initialize(adapters: Adapters.all)
      @adapters = adapters
    end

    def validate!
      themes = Lacold.themes
      validate_theme_matrix!(themes)
      validate_colors!(themes)
      validate_contrast!(themes)
      adapters.each { |adapter| adapter.render(themes) }
      true
    end

    private

    def validate_theme_matrix!(themes)
      expected = Lacold.backgrounds.size * Lacold.colors.size * Lacold.modes.size
      raise Error, "expected #{expected} themes, found #{themes.size}" unless themes.size == expected
      raise Error, "theme ids are not unique" unless themes.map(&:id).uniq.size == themes.size
    end

    def validate_colors!(themes)
      themes.each do |theme|
        raise Error, "#{theme.id} has invalid colors" unless theme.neutrals.merge(theme.accent).values.all? { |value| Color.valid?(value) }
      end
    end

    def validate_contrast!(themes)
      themes.each do |theme|
        {
          "foreground/background" => [theme.fg, theme.bg, 4.5],
          "accent/background" => [theme.primary, theme.bg, 4.5],
          "accent-secondary/background" => [theme.accent_secondary, theme.bg, 4.5],
          "foreground/selection" => [theme.fg, theme.selection, 4.5],
          "secondary/background" => [theme.secondary, theme.bg, 3.0]
        }.each do |label, (foreground, background, minimum)|
          ratio = Color.contrast(foreground, background)
          next if ratio >= minimum

          raise Error, "#{theme.id} #{label} contrast #{ratio.round(2)} is below #{minimum}"
        end
      end
    end
  end
end
