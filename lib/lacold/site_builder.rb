# frozen_string_literal: true

require "fileutils"
require "json"

module Lacold
  class SiteBuilder
    REPOSITORY = "ecnelises/lacold-theme"
    attr_reader :output_root, :themes

    def initialize(output_root:, themes:)
      @output_root = File.expand_path(output_root)
      @themes = themes
    end

    def build
      source = File.expand_path("../../site", __dir__)
      FileUtils.mkdir_p(output_root)
      Dir.glob(File.join(source, "*"), File::FNM_DOTMATCH).each do |path|
        next if %w[. ..].include?(File.basename(path))

        FileUtils.cp_r(path, output_root)
      end
      File.write(File.join(output_root, "themes.json"), "#{JSON.pretty_generate(data)}\n")
      File.write(File.join(output_root, ".nojekyll"), "")
      data
    end

    private

    def data
      available = Adapters.all.map do |adapter|
        {
          "id" => adapter.id,
          "name" => adapter.name,
          "status" => "available",
          "kind" => adapter.kind,
          "description" => adapter.description,
          "download" => "https://github.com/#{REPOSITORY}/releases/latest"
        }
      end
      {
        "version" => Lacold::VERSION,
        "repository" => "https://github.com/#{REPOSITORY}",
        "release" => "https://github.com/#{REPOSITORY}/releases/latest",
        "themes" => themes.sort_by(&:id).map(&:to_h),
        "targets" => available
      }
    end
  end
end
