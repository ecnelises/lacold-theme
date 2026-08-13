# frozen_string_literal: true

require "digest"
require "fileutils"
require "json"
require "pathname"

module Lacold
  class Builder
    attr_reader :output_root, :adapters, :themes

    def initialize(output_root:, adapters:, themes:)
      @output_root = File.expand_path(output_root)
      @adapters = adapters
      @themes = themes
    end

    def build
      FileUtils.mkdir_p(output_root)
      rendered = render_outputs
      rendered.each { |item| write(item) }
      manifest = manifest_for(rendered)
      write(Adapters::Output.new("manifest.json", "#{JSON.pretty_generate(manifest)}\n"))
      manifest
    end

    private

    def render_outputs
      seen = {}
      adapters.flat_map do |adapter|
        adapter.render(themes).each do |item|
          validate_path!(item.path)
          if seen.key?(item.path) && seen[item.path] != item.content
            raise Error, "adapters generated conflicting content for #{item.path}"
          end
          seen[item.path] = item.content
        end
      end.uniq { |item| item.path }.sort_by(&:path)
    end

    def validate_path!(relative)
      path = Pathname(relative)
      raise Error, "generated path must be relative: #{relative}" if path.absolute?
      raise Error, "generated path escapes output root: #{relative}" if path.each_filename.include?("..")
    end

    def write(item)
      destination = File.join(output_root, item.path)
      FileUtils.mkdir_p(File.dirname(destination))
      File.binwrite(destination, item.content)
    end

    def manifest_for(outputs)
      {
        "schema_version" => 1,
        "generator_version" => Lacold::VERSION,
        "backgrounds" => themes.map(&:background).uniq.sort,
        "colors" => themes.map(&:color).uniq.sort,
        "modes" => themes.map { |theme| theme.mode.to_s }.uniq.sort,
        "variants" => themes.sort_by(&:id).map(&:to_h),
        "targets" => adapters.map do |adapter|
          {
            "id" => adapter.id,
            "name" => adapter.name,
            "kind" => adapter.kind,
            "description" => adapter.description,
            "files" => outputs.select { |item| item.path.start_with?("#{adapter.id}/") }.map(&:path)
          }
        end,
        "files" => outputs.to_h do |item|
          [item.path, {"bytes" => item.content.bytesize, "sha256" => Digest::SHA256.hexdigest(item.content)}]
        end
      }
    end
  end
end
