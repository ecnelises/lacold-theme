# frozen_string_literal: true

require_relative "test_helper"
require "json"

class BuilderTest < Minitest::Test
  def test_builder_writes_manifest_and_filtered_outputs
    Dir.mktmpdir("lacold-build") do |directory|
      themes = Lacold.registry.themes(colors: ["purple"], modes: [:dark])
      manifest = Lacold::Builder.new(
        output_root: directory,
        adapters: [Lacold::Adapters.find("kitty")],
        themes: themes
      ).build

      assert File.file?(File.join(directory, "kitty/lacold-air-purple-dark.conf"))
      assert_equal ["purple"], manifest.fetch("colors")
      assert_equal 1, manifest.fetch("variants").size
      assert_equal manifest, JSON.parse(File.read(File.join(directory, "manifest.json")))
    end
  end

  def test_full_generation_is_deterministic
    digests = 2.times.map do
      Dir.mktmpdir("lacold-build") do |directory|
        manifest = Lacold::Builder.new(
          output_root: directory,
          adapters: Lacold::Adapters.all,
          themes: Lacold.registry.themes
        ).build
        manifest.fetch("files").transform_values { |metadata| metadata.fetch("sha256") }
      end
    end

    assert_equal digests.first, digests.last
  end
end

