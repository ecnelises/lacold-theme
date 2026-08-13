# frozen_string_literal: true

module Lacold
  class Theme
    attr_reader :background, :color, :mode, :neutrals, :accent

    def initialize(background:, color:, mode:, neutrals:, accent:)
      @background = background
      @color = color
      @mode = mode
      @neutrals = neutrals.freeze
      @accent = accent.freeze
      freeze
    end

    def method_missing(name, *arguments)
      return neutrals[name] if arguments.empty? && neutrals.key?(name)
      return accent[name] if arguments.empty? && accent.key?(name)

      super
    end

    def respond_to_missing?(name, include_private = false)
      neutrals.key?(name) || accent.key?(name) || super
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

    def accent_secondary
      accent.fetch(:secondary)
    end

    def accent_faint
      accent.fetch(:faint)
    end

    def ansi
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

    def to_h
      {
        "id" => id, "name" => name, "background" => background,
        "color" => color, "mode" => mode.to_s,
        "neutrals" => neutrals.transform_keys(&:to_s),
        "accent" => accent.transform_keys(&:to_s)
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
