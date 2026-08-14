# frozen_string_literal: true

require_relative "test_helper"

class PaletteTest < Minitest::Test
  def test_official_matrix_contains_ten_air_themes
    themes = Lacold.themes

    assert_equal 10, themes.size
    assert_equal ["blue", "green", "orange", "pink", "purple"], themes.map(&:color).uniq.sort
    assert_equal %i[dark light], themes.map(&:mode).uniq.sort
    assert_equal ["air"], themes.map(&:background).uniq
    assert_equal themes.size, themes.map(&:id).uniq.size
  end

  def test_air_neutrals_come_from_the_ia_reference
    light = Lacold.themes(colors: ["blue"], modes: [:light]).first
    dark = Lacold.themes(colors: ["blue"], modes: [:dark]).first

    assert_equal "#F7F7F7", light.bg
    assert_equal "#46484A", light.fg
    assert_equal "#1E1F20", dark.bg
    assert_equal "#CACBCC", dark.fg
  end

  def test_all_authored_colors_are_valid_and_readable
    Lacold.themes.each do |theme|
      theme.colors.each_value do |value|
        assert Lacold::Color.valid?(value), value
      end
      assert_operator Lacold::Color.contrast(theme.fg, theme.bg), :>=, 4.5
      assert_operator Lacold::Color.contrast(theme.primary, theme.bg), :>=, 4.5
      assert_operator Lacold::Color.contrast(theme.accent_secondary, theme.bg), :>=, 3.8
      assert_operator Lacold::Color.contrast(theme.fg, theme.selection), :>=, 4.5
      assert_operator Lacold::Color.contrast(theme.red, theme.bg), :>=, 4.5
      assert_operator Lacold::Color.contrast(theme.orange, theme.bg), :>=, 4.5
      assert_operator Lacold::Color.contrast(theme.green, theme.bg), :>=, 4.5
    end
  end

  def test_semantic_feedback_is_stable_across_accents
    themes = Lacold.themes(modes: [:light])

    assert_equal 1, themes.map(&:red).uniq.size
    assert_equal 1, themes.map(&:orange).uniq.size
    assert_equal 1, themes.map(&:green).uniq.size
    assert_equal themes.size, themes.map(&:primary).uniq.size
  end

  def test_caret_tracks_each_authored_accent
    Lacold::Palettes::MODES.each do |mode|
      themes = Lacold.themes(modes: [mode])

      assert_equal themes.size, themes.map(&:caret).uniq.size
      themes.each { |theme| assert_equal theme.primary, theme.caret }
    end
  end

end
