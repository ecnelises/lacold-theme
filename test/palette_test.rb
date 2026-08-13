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

    assert_equal "#FAFAF9", light.bg
    assert_equal "#25272A", light.fg
    assert_equal "#1E1F20", dark.bg
    assert_equal "#CACBCC", dark.fg
  end

  def test_all_authored_colors_are_valid_and_readable
    Lacold.themes.each do |theme|
      theme.neutrals.merge(theme.accent).each_value do |value|
        assert Lacold::Color.valid?(value), value
      end
      assert_operator Lacold::Color.contrast(theme.fg, theme.bg), :>=, 4.5
      assert_operator Lacold::Color.contrast(theme.primary, theme.bg), :>=, 4.5
      assert_operator Lacold::Color.contrast(theme.accent_secondary, theme.bg), :>=, 4.5
      assert_operator Lacold::Color.contrast(theme.fg, theme.selection), :>=, 4.5
    end
  end

end
