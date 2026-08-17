# frozen_string_literal: true

module Lacold
  class Theme
    attr_reader :background, :color, :mode, :neutrals, :accent, :semantics, :spectrum, :syntax

    def initialize(background:, color:, mode:, neutrals:, accent:, semantics:, spectrum: {}, syntax: {})
      @background = background
      @color = color
      @mode = mode
      @neutrals = neutrals.freeze
      @accent = accent.freeze
      @semantics = semantics.freeze
      @spectrum = spectrum.freeze
      @syntax = syntax.freeze
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

    def family_id
      "lacold-#{background}-#{color}"
    end

    def name
      "Lacold #{background.capitalize} #{color.capitalize} #{mode.to_s.capitalize}"
    end

    def family_name
      "Lacold #{background.capitalize} #{color.capitalize}"
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

    def syntax_color(role, fallback)
      syntax.fetch(role, fallback)
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
        .merge(spectrum.transform_keys { |key| :"spectrum_#{key}" })
        .merge(syntax.transform_keys { |key| :"syntax_#{key}" })
    end

    def to_h
      {
        "id" => id, "name" => name, "background" => background,
        "color" => color, "mode" => mode.to_s,
        "neutrals" => neutrals.transform_keys(&:to_s),
        "accent" => accent.transform_keys(&:to_s),
        "semantics" => semantics.transform_keys(&:to_s),
        "spectrum" => spectrum.transform_keys(&:to_s),
        "syntax" => syntax.transform_keys(&:to_s)
      }
    end

    def textmate_settings
      [
        ["Comments", %w[comment punctuation.definition.comment], muted, "italic"],
        ["Keywords and storage", %w[keyword storage.type storage.modifier keyword.control keyword.operator.expression], syntax_color(:keyword, primary), nil],
        ["Types, classes and namespaces", %w[entity.name.type entity.name.class entity.name.namespace support.type support.class variable.language], syntax_color(:type, accent_secondary), nil],
        ["Language support and macros", %w[support.constant support.function entity.name.function.preprocessor entity.name.function.macro], syntax_color(:macro, accent_secondary), nil],
        ["Functions and methods", %w[entity.name.function meta.function-call support.function.any-method], syntax_color(:function, fg), nil],
        ["Variables and parameters", %w[variable variable.parameter variable.other.property meta.object-literal.key support.variable.property], syntax_color(:variable, fg), nil],
        ["Properties and object keys", %w[variable.other.property meta.object-literal.key support.variable.property], syntax_color(:property, fg), nil],
        ["Strings stay ink", %w[string], syntax_color(:string, fg), nil],
        ["Numbers", %w[constant.numeric], syntax_color(:number, fg), nil],
        ["Constants and symbols", %w[constant.language constant.character constant.other], syntax_color(:constant, fg), nil],
        ["Tags", %w[entity.name.tag], syntax_color(:tag, primary), nil],
        ["Attributes and decorators", %w[entity.other.attribute-name meta.decorator entity.name.function.decorator punctuation.decorator], syntax_color(:attribute, primary), nil],
        ["Punctuation and operators", %w[punctuation keyword.operator meta.brace meta.delimiter], syntax_color(:operator, self.secondary), nil],
        ["Markdown headings", %w[markup.heading entity.name.section], selection_fg, "bold"],
        ["Markdown emphasis", %w[markup.bold], selection_fg, "bold"],
        ["Markdown italic", %w[markup.italic], fg, "italic"],
        ["Links", %w[markup.underline.link string.other.link meta.link], syntax_color(:link, primary), "underline"],
        ["Invalid and deprecated", %w[invalid invalid.illegal], red, "underline"],
        ["Diff added", %w[markup.inserted], green, nil],
        ["Diff changed", %w[markup.changed], primary, nil],
        ["Diff deleted", %w[markup.deleted], red, nil]
      ]
    end
  end
end
