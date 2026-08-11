# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))

require "lacold"
require "minitest/autorun"
require "stringio"
require "tmpdir"

class Minitest::Test
  def setup
    Lacold.reset_registry!
  end
end

