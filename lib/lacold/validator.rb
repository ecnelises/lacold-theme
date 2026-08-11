# frozen_string_literal: true

require "digest"
require "json"
require "tmpdir"

module Lacold
  class Validator
    attr_reader :registry, :adapters

    def initialize(registry: Lacold.registry, adapters: Adapters.all)
      @registry = registry
      @adapters = adapters
    end

    def validate!
      themes = registry.themes
      validate_theme_matrix!(themes)
      validate_contrast!(themes)
      validate_determinism!(themes)
      true
    end

    private

    def validate_theme_matrix!(themes)
      expected = registry.backgrounds.size * registry.colors.size * registry.modes.size
      raise Error, "expected #{expected} themes, found #{themes.size}" unless themes.size == expected
      raise Error, "theme ids are not unique" unless themes.map(&:id).uniq.size == themes.size
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

    def validate_determinism!(themes)
      first = build_in_temp(themes)
      second = build_in_temp(themes)
      raise Error, "generation is not deterministic" unless first == second
    end

    def build_in_temp(themes)
      Dir.mktmpdir("lacold-check") do |directory|
        Builder.new(output_root: directory, adapters: adapters, themes: themes).build
        validate_generated!(directory)
        files = Dir.glob(File.join(directory, "**", "*"), File::FNM_DOTMATCH).select { |path| File.file?(path) }
        return files.to_h do |path|
          [path.delete_prefix("#{directory}/"), Digest::SHA256.file(path).hexdigest]
        end
      end
    end

    def validate_generated!(directory)
      require "rexml/document"
      Dir.glob(File.join(directory, "**", "*.json")).each { |path| JSON.parse(File.read(path)) }
      Dir.glob(File.join(directory, "**", "*.{tmTheme,itermcolors,terminal,xccolortheme,icls,xml,vstheme}")).each do |path|
        REXML::Document.new(File.read(path))
      end
      manifest = JSON.parse(File.read(File.join(directory, "manifest.json")))
      raise Error, "manifest variants missing" unless manifest.fetch("variants").size == registry.themes.size

      Dir.glob(File.join(directory, "terminal-app", "*.terminal")).each do |path|
        data = File.read(path).scan(%r{<data>\s*(.*?)\s*</data>}m).flatten.first
        archive = data.to_s.gsub(/\s+/, "").unpack1("m0")
        raise Error, "invalid Terminal.app color archive in #{path}" unless archive.start_with?("bplist00")
      end
    rescue JSON::ParserError, REXML::ParseException => error
      raise Error, "generated file failed validation: #{error.message}"
    end
  end
end
