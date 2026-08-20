# frozen_string_literal: true

require_relative "test_helper"
require "json"

class SiteBuilderTest < Minitest::Test
  def test_site_contains_generated_theme_data_and_all_carriers
    Dir.mktmpdir("lacold-site") do |directory|
      Lacold::SiteBuilder.new(output_root: directory, themes: Lacold.themes).build
      data = JSON.parse(File.read(File.join(directory, "themes.json")))

      assert File.file?(File.join(directory, "index.html"))
      assert File.file?(File.join(directory, ".nojekyll"))
      assert_equal 12, data.fetch("themes").size
      assert_equal 27, data.fetch("targets").size
      assert_equal 27, data.fetch("targets").count { |target| target.fetch("status") == "available" }
      refute data.fetch("targets").any? { |target| target.fetch("status") == "planned" }
      codex = data.fetch("targets").find { |target| target.fetch("id") == "codex" }
      assert codex
      assert_equal "Codex CLI", codex.fetch("name")
      rainbow = data.fetch("themes").find { |theme| theme.fetch("id") == "lacold-air-rainbow-light" }
      assert_equal "#6F55A3", rainbow.dig("syntax", "keyword")
      assert_equal "#A64050", rainbow.dig("syntax", "attribute")
      assert_equal %w[red orange yellow green cyan blue violet ink gray], rainbow.fetch("spectrum").keys
    end
  end
end
