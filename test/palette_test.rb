# frozen_string_literal: true

require_relative "test_helper"

class PaletteTest < Minitest::Test
  def test_official_matrix_contains_twelve_air_themes
    themes = Lacold.themes

    assert_equal 12, themes.size
    assert_equal ["blue", "green", "orange", "pink", "purple", "rainbow"], themes.map(&:color).uniq.sort
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

  def test_light_and_dark_variants_share_a_family_identity
    light, dark = Lacold.themes(colors: ["blue"])

    assert_equal "lacold-air-blue", light.family_id
    assert_equal light.family_id, dark.family_id
    assert_equal "Lacold Air Blue", light.family_name
    assert_equal light.family_name, dark.family_name
  end

  def test_all_authored_colors_are_valid_and_readable
    Lacold.themes.each do |theme|
      theme.colors.each_value do |value|
        assert Lacold::Color.valid?(value), value
      end
      theme.syntax.each_value do |value|
        assert_operator Lacold::Color.contrast(value, theme.bg), :>=, 4.5, "#{theme.id}: #{value}"
      end
      theme.spectrum.each_value do |value|
        assert_operator Lacold::Color.contrast(value, theme.bg), :>=, 4.5, "#{theme.id}: #{value}"
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

  def test_rainbow_maps_all_seven_hues_plus_ink_and_gray_to_syntax
    theme = Lacold.themes(colors: ["rainbow"], modes: [:light]).first

    assert_equal "#6F55A3", theme.syntax_color(:keyword, theme.primary)
    assert_equal "#3874AC", theme.syntax_color(:type, theme.accent_secondary)
    assert_equal "#3F747D", theme.syntax_color(:function, theme.fg)
    assert_equal "#2F7653", theme.syntax_color(:string, theme.fg)
    assert_equal "#7E6000", theme.syntax_color(:constant, theme.fg)
    assert_equal "#9A4D16", theme.syntax_color(:number, theme.fg)
    assert_equal "#A64050", theme.syntax_color(:attribute, theme.primary)
    assert_equal "#A64050", theme.syntax_color(:property, theme.fg)
    assert_equal theme.fg, theme.syntax_color(:variable, theme.fg)
    assert_equal theme.secondary, theme.syntax_color(:operator, theme.secondary)
  end

  def test_rainbow_spectrum_has_seven_chromatic_and_two_neutral_lanes
    roles = %i[red orange yellow green cyan blue violet ink gray]

    Lacold::Palettes::MODES.each do |mode|
      rainbow = Lacold.themes(colors: ["rainbow"], modes: [mode]).first

      assert_equal roles, rainbow.spectrum.keys
      assert_equal roles.size, rainbow.spectrum.values.uniq.size
      assert_equal rainbow.spectrum.fetch(:violet), rainbow.syntax.fetch(:keyword)
      assert_equal rainbow.spectrum.fetch(:blue), rainbow.syntax.fetch(:type)
      assert_equal rainbow.spectrum.fetch(:cyan), rainbow.syntax.fetch(:function)
      assert_equal rainbow.spectrum.fetch(:green), rainbow.syntax.fetch(:string)
      assert_equal rainbow.spectrum.fetch(:yellow), rainbow.syntax.fetch(:constant)
      assert_equal rainbow.spectrum.fetch(:orange), rainbow.syntax.fetch(:number)
      assert_equal rainbow.spectrum.fetch(:red), rainbow.syntax.fetch(:attribute)
      assert_equal rainbow.spectrum.fetch(:ink), rainbow.syntax.fetch(:variable)
      assert_equal rainbow.spectrum.fetch(:gray), rainbow.syntax.fetch(:operator)
    end
  end

  def test_caret_tracks_each_authored_accent
    Lacold::Palettes::MODES.each do |mode|
      themes = Lacold.themes(modes: [mode])

      assert_equal themes.size, themes.map(&:caret).uniq.size
      themes.each { |theme| assert_equal theme.primary, theme.caret }
    end
  end

end
