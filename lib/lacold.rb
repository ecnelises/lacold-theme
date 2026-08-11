# frozen_string_literal: true

require_relative "lacold/version"
require_relative "lacold/color"
require_relative "lacold/palette"
require_relative "lacold/theme"
require_relative "lacold/registry"
require_relative "lacold/palettes"
require_relative "lacold/binary_plist"
require_relative "lacold/adapters"
require_relative "lacold/builder"
require_relative "lacold/site_builder"
require_relative "lacold/validator"
require_relative "lacold/cli"

module Lacold
  class Error < StandardError; end

  class << self
    attr_writer :registry

    def registry
      @registry ||= Palettes.build_registry
    end

    def configure
      yield registry
    end

    def reset_registry!
      @registry = Palettes.build_registry
    end
  end
end

