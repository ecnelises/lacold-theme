# frozen_string_literal: true

module Lacold
  class Theme
    attr_reader :palette

    def initialize(palette)
      @palette = palette
    end

    def method_missing(name, *arguments)
      return palette.public_send(name, *arguments) if arguments.empty? && palette.respond_to?(name)
      return palette[name] if arguments.empty? && (palette.neutrals.key?(name) || palette.accent.key?(name))

      super
    end

    def respond_to_missing?(name, include_private = false)
      palette.respond_to?(name) || palette.neutrals.key?(name) || palette.accent.key?(name) || super
    end

    def accent_secondary
      palette.accent.fetch(:secondary)
    end

    def accent_faint
      palette.accent.fetch(:faint)
    end

    def ansi
      # ANSI semantics stay legible but deliberately remain within one hue.
      {
        black: bg,
        red: strong,
        green: primary,
        yellow: accent_secondary,
        blue: primary,
        magenta: accent_secondary,
        cyan: accent_faint,
        white: fg,
        bright_black: muted,
        bright_red: primary,
        bright_green: accent_secondary,
        bright_yellow: accent_faint,
        bright_blue: strong,
        bright_magenta: primary,
        bright_cyan: accent_secondary,
        bright_white: dark? ? "#FFFFFF" : fg
      }
    end

    def textmate_settings
      [
        ["Comment", %w[comment punctuation.definition.comment], muted, "italic"],
        ["Keyword", %w[keyword storage.type storage.modifier], primary, nil],
        ["Type", %w[entity.name.type entity.name.class support.type entity.name.namespace], accent_secondary, nil],
        ["Function", %w[entity.name.function support.function variable.function], fg, "bold"],
        ["String", %w[string constant.character], fg, nil],
        ["Constant", %w[constant.numeric constant.language], fg, nil],
        ["Property", %w[variable.other.property entity.other.attribute-name], fg, nil],
        ["Operator", %w[keyword.operator punctuation meta.delimiter], self.secondary, nil],
        ["Markup heading", %w[markup.heading], primary, "bold"],
        ["Link", %w[markup.underline.link string.other.link], primary, "underline"],
        ["Inserted", %w[markup.inserted], accent_secondary, nil],
        ["Deleted", %w[markup.deleted invalid], strong, "underline"]
      ]
    end
  end
end
