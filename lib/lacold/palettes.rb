# frozen_string_literal: true

module Lacold
  module Palettes
    AIR_LIGHT = {
      bg: "#FAFAF9", surface: "#F3F4F3", raised: "#E9EBEA",
      line: "#F0F2F2", border: "#CED1D0",
      fg: "#25272A", secondary: "#565A5E", muted: "#777B7F", faint: "#A3A7AA",
      line_nr: "#8C9093", line_nr_active: "#3D4145", whitespace: "#B7BAB9"
    }.freeze

    AIR_DARK = {
      bg: "#1E1F20", surface: "#242526", raised: "#2B2C2D",
      line: "#272829", border: "#3C3E40",
      fg: "#CACBCC", secondary: "#9B9D9F", muted: "#6C6E70", faint: "#505254",
      line_nr: "#656769", line_nr_active: "#B7B9BB", whitespace: "#444648"
    }.freeze

    ACCENTS = {
      "blue" => {
        light: {
          strong: "#176EAF", primary: "#2478B8", secondary: "#3D789F", faint: "#85ADD0",
          wash: "#DCEAF4", selection: "#CEE2F3", inactive_selection: "#E3E9ED", bracket: "#D8E7F2"
        },
        dark: {
          strong: "#82B5DE", primary: "#6899C2", secondary: "#7E9EB8", faint: "#506F89",
          wash: "#293C4D", selection: "#34495B", inactive_selection: "#2C3135", bracket: "#304554"
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

    module_function

    def build_registry
      Registry.new
        .register_background("air", light: AIR_LIGHT, dark: AIR_DARK)
        .tap do |registry|
          ACCENTS.each do |name, modes|
            registry.register_accent(name, light: modes.fetch(:light), dark: modes.fetch(:dark))
          end
        end
    end
  end
end
