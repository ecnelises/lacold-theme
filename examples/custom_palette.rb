# This file is executed as Ruby by `bin/lacold --config`. Load only trusted
# configuration files. Every role is hand authored for both modes.
Lacold.configure do |config|
  config.register_accent(
    "teal",
    light: {
      strong: "#17645F", primary: "#267670", secondary: "#4B7C78", faint: "#82AAA7",
      wash: "#DCEAE8", selection: "#D2E6E3", inactive_selection: "#E4EBEA", bracket: "#D8E7E5"
    },
    dark: {
      strong: "#86C0BA", primary: "#70AAA4", secondary: "#83A7A3", faint: "#50736F",
      wash: "#2C4140", selection: "#34504D", inactive_selection: "#2D3534", bracket: "#304744"
    }
  )
end

