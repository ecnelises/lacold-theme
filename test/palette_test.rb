# frozen_string_literal: true

require_relative "test_helper"

class PaletteTest < Minitest::Test
  def test_official_matrix_contains_ten_air_themes
    themes = Lacold.registry.themes

    assert_equal 10, themes.size
    assert_equal ["blue", "green", "orange", "pink", "purple"], themes.map(&:color).uniq.sort
    assert_equal %i[dark light], themes.map(&:mode).uniq.sort
    assert_equal ["air"], themes.map(&:background).uniq
    assert_equal themes.size, themes.map(&:id).uniq.size
  end

  def test_air_neutrals_come_from_the_ia_reference
    light = Lacold.registry.themes(colors: ["blue"], modes: [:light]).first
    dark = Lacold.registry.themes(colors: ["blue"], modes: [:dark]).first

    assert_equal "#FAFAF9", light.bg
    assert_equal "#25272A", light.fg
    assert_equal "#1E1F20", dark.bg
    assert_equal "#CACBCC", dark.fg
  end

  def test_all_authored_colors_are_valid_and_readable
    Lacold.registry.themes.each do |theme|
      theme.palette.neutrals.merge(theme.palette.accent).each_value do |value|
        assert Lacold::Color.valid?(value), value
      end
      assert_operator Lacold::Color.contrast(theme.fg, theme.bg), :>=, 4.5
      assert_operator Lacold::Color.contrast(theme.primary, theme.bg), :>=, 4.5
      assert_operator Lacold::Color.contrast(theme.accent_secondary, theme.bg), :>=, 4.5
      assert_operator Lacold::Color.contrast(theme.fg, theme.selection), :>=, 4.5
    end
  end

  def test_dense_is_reserved_but_not_defined
    error = assert_raises(Lacold::Error) { Lacold.registry.themes(backgrounds: ["dense"]) }
    assert_match(/unknown background: dense/, error.message)
  end

  def test_registry_accepts_a_custom_hand_authored_accent
    original = Lacold::Palettes::ACCENTS.fetch("green")
    Lacold.configure do |config|
      config.register_accent("custom", light: original.fetch(:light), dark: original.fetch(:dark))
    end

    theme = Lacold.registry.themes(colors: ["custom"], modes: [:light]).first
    assert_equal "lacold-air-custom-light", theme.id
  end
end

