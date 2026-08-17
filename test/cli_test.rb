# frozen_string_literal: true

require_relative "test_helper"

class CLITest < Minitest::Test
  def test_list_reports_public_dimensions
    output = StringIO.new
    status = Lacold::CLI.run(["list"], out: output, err: StringIO.new)

    assert_equal 0, status
    assert_includes output.string, "Backgrounds: air"
    assert_includes output.string, "Colors: blue, green, orange, pink, purple, rainbow"
  end

  def test_build_filters_target_color_and_mode
    Dir.mktmpdir("lacold-cli") do |directory|
      output = StringIO.new
      status = Lacold::CLI.run(
        ["build", "--target", "kitty", "--color", "green", "--mode", "dark", "--output", directory],
        out: output,
        err: StringIO.new
      )

      assert_equal 0, status
      assert File.file?(File.join(directory, "kitty/lacold-air-green-dark.conf"))
      refute File.exist?(File.join(directory, "vscode"))
    end
  end

  def test_unknown_target_returns_a_failure
    errors = StringIO.new
    status = Lacold::CLI.run(["build", "--target", "missing"], out: StringIO.new, err: errors)

    assert_equal 1, status
    assert_match(/unknown target/, errors.string)
  end
end
