# frozen_string_literal: true

module Lacold
  module Palettes
    BACKGROUND = "air"
    MODES = %i[light dark].freeze

    AIR_LIGHT = {
      bg: "#F7F7F7", surface: "#F2F2F1", raised: "#ECEDEB",
      line: "#F3F4F2", border: "#DADBDA",
      fg: "#46484A", secondary: "#65686B", muted: "#878A8D", faint: "#AEB1B3",
      line_nr: "#AEB1B3", line_nr_active: "#65686B", whitespace: "#AEB1B3"
    }.freeze

    AIR_DARK = {
      bg: "#1E1F20", surface: "#242526", raised: "#2A2C2F",
      line: "#272829", border: "#34373B",
      fg: "#CACBCC", secondary: "#9B9D9F", muted: "#6C6E70", faint: "#505254",
      line_nr: "#4F5256", line_nr_active: "#9B9D9F", whitespace: "#4F5256"
    }.freeze

    # Status colors are deliberately independent from the selected accent.
    # They are rare, functional annotations: diagnostics, diffs, search,
    # terminal ANSI colors, and shell state.  This is the part of the original
    # iA configuration that should remain legible even in a non-blue variant.
    SEMANTIC_LIGHT = {
      caret: "#03C0FF", selection_fg: "#2F3133", tab_bg: "#F5F5F3",
      red: "#AA4949", red_bright: "#B65A5A", red_wash: "#F3DCDD",
      orange: "#9D5419", orange_bright: "#B46A30", orange_wash: "#F5E1D2",
      yellow: "#7E6000", yellow_bright: "#94720A", yellow_wash: "#F4EBC5",
      green: "#417553", green_bright: "#528364", green_wash: "#DDEBDD",
      purple: "#705B9D", purple_bright: "#806BAA", purple_wash: "#E8E0F1",
      cyan: "#4D7D86", cyan_bright: "#5E8D96",
      terminal_black: "#2F3133", terminal_bright_black: "#878A8D",
      terminal_white: "#D7D9D7", terminal_bright_white: "#FAFAF9"
    }.freeze

    SEMANTIC_DARK = {
      caret: "#03C0FF", selection_fg: "#DCDDDE", tab_bg: "#232528",
      red: "#D57171", red_bright: "#DF8585", red_wash: "#492E31",
      orange: "#D58446", orange_bright: "#E19A62", orange_wash: "#493429",
      yellow: "#CCA643", yellow_bright: "#D8B75C", yellow_wash: "#4A4024",
      green: "#71A482", green_bright: "#85B494", green_wash: "#2D4235",
      purple: "#A18BCF", purple_bright: "#B09BDD", purple_wash: "#3B3149",
      cyan: "#75A7AF", cyan_bright: "#89B7BE",
      terminal_black: "#292B2E", terminal_bright_black: "#76797D",
      terminal_white: "#BEC0C2", terminal_bright_white: "#E7E8E9"
    }.freeze

    ACCENTS = {
      "blue" => {
        light: {
          strong: "#2E679B", primary: "#3874AC", secondary: "#5280A9", faint: "#85ADD0",
          wash: "#DCEAF4", selection: "#DCE8F3", inactive_selection: "#E8ECEF", bracket: "#E2EAF0"
        },
        dark: {
          strong: "#82B5DE", primary: "#6899C2", secondary: "#7E9EB8", faint: "#506F89",
          wash: "#293C4D", selection: "#344657", inactive_selection: "#2D3339", bracket: "#30404D"
        }
      },
      "pink" => {
        light: {
          strong: "#8D245E", primary: "#A23B72", secondary: "#9A5B79", faint: "#C58CAB",
          wash: "#F1DFE9", selection: "#EDD4E2", inactive_selection: "#EEE7EA", bracket: "#EBDCE5"
        },
        dark: {
          strong: "#E493BA", primary: "#D47BA8", secondary: "#C58AA6", faint: "#82556C",
          wash: "#49303D", selection: "#563548", inactive_selection: "#352C31", bracket: "#49323F"
        }
      },
      "green" => {
        light: {
          strong: "#236443", primary: "#2F7653", secondary: "#4D7B63", faint: "#82AE97",
          wash: "#DCEAE2", selection: "#D3E7DC", inactive_selection: "#E5EBE7", bracket: "#D9E8DF"
        },
        dark: {
          strong: "#8BC29F", primary: "#75AC8D", secondary: "#86A995", faint: "#517663",
          wash: "#2D4135", selection: "#34513F", inactive_selection: "#2D3530", bracket: "#30483A"
        }
      },
      "purple" => {
        light: {
          strong: "#5D428D", primary: "#6F55A3", secondary: "#7C689D", faint: "#A997C8",
          wash: "#E8E2F1", selection: "#E1D8ED", inactive_selection: "#EAE7ED", bracket: "#E4DDED"
        },
        dark: {
          strong: "#B9A4E6", primary: "#A18BCF", secondary: "#AD9BCB", faint: "#6C5E88",
          wash: "#3B3149", selection: "#493C5D", inactive_selection: "#322E37", bracket: "#40364F"
        }
      },
      "orange" => {
        light: {
          strong: "#843D0C", primary: "#9A4D16", secondary: "#8B6345", faint: "#C18C65",
          wash: "#F3E2D6", selection: "#EED9C9", inactive_selection: "#EEE8E4", bracket: "#EADFD7"
        },
        dark: {
          strong: "#E7A16D", primary: "#D78A50", secondary: "#C99570", faint: "#8B6045",
          wash: "#493429", selection: "#563B2C", inactive_selection: "#352F2B", bracket: "#49372D"
        }
      }
    }.freeze

    AIR = {light: AIR_LIGHT, dark: AIR_DARK}.freeze
    SEMANTICS = {light: SEMANTIC_LIGHT, dark: SEMANTIC_DARK}.freeze

    module_function

    def themes(colors: ACCENTS.keys.sort, modes: MODES)
      colors = Array(colors).map { |value| value.to_s.downcase }
      modes = Array(modes).map { |value| value.to_s.downcase.to_sym }
      validate!(colors, ACCENTS.keys, "color")
      validate!(modes, MODES, "mode")

      colors.product(modes).map do |color, mode|
        Theme.new(
          background: BACKGROUND, color: color, mode: mode,
          neutrals: AIR.fetch(mode),
          accent: ACCENTS.fetch(color).fetch(mode),
          semantics: SEMANTICS.fetch(mode)
        )
      end
    end

    def validate!(selected, available, kind)
      unknown = selected - available
      return if unknown.empty?

      raise Error, "unknown #{kind}: #{unknown.join(', ')} (available: #{available.join(', ')})"
    end
    private_class_method :validate!
  end
end
