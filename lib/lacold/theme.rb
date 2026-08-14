# frozen_string_literal: true

module Lacold
  class Theme
    attr_reader :background, :color, :mode, :neutrals, :accent, :semantics

    def initialize(background:, color:, mode:, neutrals:, accent:, semantics:)
      @background = background
      @color = color
      @mode = mode
      @neutrals = neutrals.freeze
      @accent = accent.freeze
      @semantics = semantics.freeze
      freeze
    end

    def method_missing(name, *arguments)
      return neutrals[name] if arguments.empty? && neutrals.key?(name)
      return accent[name] if arguments.empty? && accent.key?(name)
      return semantics[name] if arguments.empty? && semantics.key?(name)

      super
    end

    def respond_to_missing?(name, include_private = false)
      neutrals.key?(name) || accent.key?(name) || semantics.key?(name) || super
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

    def caret
      primary
    end

    def ansi
      {
        black: terminal_black,
        red: red,
        green: green,
        yellow: yellow,
        blue: primary,
        magenta: purple,
        cyan: cyan,
        white: terminal_white,
        bright_black: terminal_bright_black,
        bright_red: red_bright,
        bright_green: green_bright,
        bright_yellow: yellow_bright,
        bright_blue: accent_secondary,
        bright_magenta: purple_bright,
        bright_cyan: cyan_bright,
        bright_white: terminal_bright_white
      }
    end

    def colors
      neutrals
        .merge(accent.transform_keys { |key| :"accent_#{key}" })
        .merge(semantics.transform_keys { |key| :"semantic_#{key}" })
    end

    def to_h
      {
        "id" => id, "name" => name, "background" => background,
        "color" => color, "mode" => mode.to_s,
        "neutrals" => neutrals.transform_keys(&:to_s),
        "accent" => accent.transform_keys(&:to_s),
        "semantics" => semantics.transform_keys(&:to_s)
      }
    end

    def textmate_settings
      [
        ["Comments", %w[comment punctuation.definition.comment], muted, "italic"],
        ["Keywords and storage", %w[keyword storage.type storage.modifier keyword.control keyword.operator.expression], primary, nil],
        ["Types, classes, namespaces and language support", %w[entity.name.type entity.name.class entity.name.namespace support.type support.class support.constant support.function variable.language], accent_secondary, nil],
        ["Functions and methods stay ink", %w[entity.name.function meta.function-call support.function.any-method], fg, nil],
        ["Variables, properties and parameters stay ink", %w[variable variable.parameter variable.other.property meta.object-literal.key support.variable.property], fg, nil],
        ["Strings, numbers and constants stay ink", %w[string constant.numeric constant.language constant.character constant.other], fg, nil],
        ["Tags and attributes", %w[entity.name.tag entity.other.attribute-name], primary, nil],
        ["Punctuation and operators", %w[punctuation keyword.operator meta.brace meta.delimiter], self.secondary, nil],
        ["Markdown headings", %w[markup.heading entity.name.section], selection_fg, "bold"],
        ["Markdown emphasis", %w[markup.bold], selection_fg, "bold"],
        ["Markdown italic", %w[markup.italic], fg, "italic"],
        ["Links", %w[markup.underline.link string.other.link meta.link], primary, "underline"],
        ["Invalid and deprecated", %w[invalid invalid.illegal], red, "underline"],
        ["Diff added", %w[markup.inserted], green, nil],
        ["Diff changed", %w[markup.changed], primary, nil],
        ["Diff deleted", %w[markup.deleted], red, nil]
      ]
    end
  end
end
