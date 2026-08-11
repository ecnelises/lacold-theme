# frozen_string_literal: true

require_relative "test_helper"
require "json"

class SiteBuilderTest < Minitest::Test
  def test_site_contains_generated_theme_data_and_all_carriers
    Dir.mktmpdir("lacold-site") do |directory|
      Lacold::SiteBuilder.new(output_root: directory, themes: Lacold.registry.themes).build
      data = JSON.parse(File.read(File.join(directory, "themes.json")))

      assert File.file?(File.join(directory, "index.html"))
      assert File.file?(File.join(directory, ".nojekyll"))
      assert_equal 10, data.fetch("themes").size
      assert_equal 27, data.fetch("targets").size
      assert_equal 27, data.fetch("targets").count { |target| target.fetch("status") == "available" }
      refute data.fetch("targets").any? { |target| target.fetch("status") == "planned" }
    end
  end
end
