# frozen_string_literal: true

require "optparse"

module Lacold
  class CLI
    class << self
      def run(arguments, out: $stdout, err: $stderr)
        new(arguments, out: out, err: err).run
      rescue Error, OptionParser::ParseError => error
        err.puts "lacold: #{error.message}"
        1
      end
    end

    def initialize(arguments, out:, err:)
      @arguments = arguments.dup
      @out = out
      @err = err
      @options = {output: "dist"}
    end

    def run
      command = @arguments.shift || "help"
      case command
      when "build" then build
      when "site" then site
      when "check" then check
      when "list" then list
      when "version", "--version", "-v" then @out.puts(Lacold::VERSION); 0
      when "help", "--help", "-h" then @out.puts(help); 0
      else raise Error, "unknown command: #{command}"
      end
    end

    private

    def build
      parse_common!(output: "dist", targets: true)
      themes = selected_themes
      adapters = selected_adapters
      manifest = Builder.new(output_root: @options[:output], adapters: adapters, themes: themes).build
      @out.puts "Generated #{manifest.fetch('files').size} files for #{themes.size} themes in #{@options[:output]}"
      0
    end

    def site
      parse_common!(output: "_site", targets: false)
      themes = selected_themes
      SiteBuilder.new(output_root: @options[:output], themes: themes).build
      @out.puts "Built Lacold demo in #{@options[:output]}"
      0
    end

    def check
      raise OptionParser::InvalidOption, @arguments.join(" ") unless @arguments.empty?
      Validator.new.validate!
      @out.puts "Validated #{Lacold.themes.size} themes and #{Adapters.all.size} targets"
      0
    end

    def list
      raise OptionParser::InvalidOption, @arguments.join(" ") unless @arguments.empty?
      @out.puts "Backgrounds: #{Lacold.backgrounds.join(', ')}"
      @out.puts "Colors: #{Lacold.colors.join(', ')}"
      @out.puts "Modes: #{Lacold.modes.join(', ')}"
      @out.puts "Targets: #{Adapters.ids.join(', ')}"
      0
    end

    def parse_common!(output:, targets:)
      @options[:output] = output
      parser = OptionParser.new do |options|
        options.on("-o", "--output DIRECTORY", "Output directory") { |value| @options[:output] = value }
        options.on("--color NAMES", "Comma-separated colors") { |value| @options[:colors] = split(value) }
        options.on("--mode NAMES", "Comma-separated modes") { |value| @options[:modes] = split(value).map(&:to_sym) }
        if targets
          options.on("--target NAMES", "Comma-separated targets") { |value| @options[:targets] = split(value) }
        end
      end
      parser.parse!(@arguments)
      raise OptionParser::InvalidOption, @arguments.join(" ") unless @arguments.empty?
    end

    def split(value)
      value.split(",").map(&:strip).reject(&:empty?)
    end

    def selected_themes
      Lacold.themes(
        colors: @options[:colors] || Lacold.colors,
        modes: @options[:modes] || Lacold.modes
      )
    end

    def selected_adapters
      return Adapters.all unless @options[:targets]

      @options[:targets].map { |target| Adapters.find(target) }.uniq
    end

    def help
      <<~HELP
        Lacold #{Lacold::VERSION} — generate restrained ink-first themes

        Usage:
          bin/lacold list
          bin/lacold build [--target NAMES] [--color NAMES] [--mode NAMES]
                           [--output DIR]
          bin/lacold site [--color NAMES] [--mode NAMES] [--output DIR]
          bin/lacold check
          bin/lacold version
      HELP
    end
  end
end
