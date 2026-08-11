# frozen_string_literal: true

require_relative "test_helper"
require "open3"

class BinaryPlistTest < Minitest::Test
  def test_keyed_color_is_a_binary_plist
    archive = Lacold::BinaryPlist.keyed_color("#112233")

    assert archive.start_with?("bplist00")
    assert_operator archive.bytesize, :>, 100
    assert_includes archive, "NSKeyedArchiver"
    assert_includes archive, "NSColor"
  end

  def test_macos_can_read_the_archive
    skip "AppKit is available only on macOS" unless RUBY_PLATFORM.include?("darwin")

    Dir.mktmpdir("lacold-color") do |directory|
      path = File.join(directory, "color.plist")
      File.binwrite(path, Lacold::BinaryPlist.keyed_color("#2478B8"))
      assert system("plutil", "-lint", path, out: File::NULL, err: File::NULL)

      swift = <<~SWIFT
        import AppKit
        let data = try! Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))
        let value = try! NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as! NSColor
        print(value.colorSpace.colorSpaceModel.rawValue)
      SWIFT
      cache = File.join(directory, "swift-cache")
      output, errors, status = Open3.capture3(
        {"CLANG_MODULE_CACHE_PATH" => cache},
        "swift", "-e", swift, path
      )
      assert status.success?, errors
      assert_match(/1/, output)
    end
  end
end
