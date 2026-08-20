# frozen_string_literal: true

require_relative "test_helper"

class CLITest < Minitest::Test
  def test_list_reports_public_dimensions
    output = StringIO.new
    status = Lacold::CLI.run(["list"], out: output, err: StringIO.new)

    assert_equal 0, status
    assert_includes output.string, "Backgrounds: air"
    assert_includes output.string, "Colors: blue, green, orange, pink, purple, rainbow"
    assert_match(/^Targets: .*\bcodex\b/, output.string)
  end

  def test_build_generates_codex_theme_and_config
    Dir.mktmpdir("lacold-cli") do |directory|
      status = Lacold::CLI.run(
        ["build", "--target", "codex", "--color", "blue", "--mode", "dark", "--output", directory],
        out: StringIO.new,
        err: StringIO.new
      )

      assert_equal 0, status
      assert File.file?(File.join(directory, "codex/themes/lacold-air-blue-dark.tmTheme"))
      assert File.file?(File.join(directory, "codex/config/lacold-air-blue-dark.toml"))
      refute File.exist?(File.join(directory, "vscode"))
    end
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
