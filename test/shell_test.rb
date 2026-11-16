# frozen_string_literal: true

require_relative "test_helper"
require "lacold/shell"
require "lacold/json_settings"
require "open3"

class ShellTest < Minitest::Test
  def setup
    @home = Dir.mktmpdir("lacold home '")
    @environment = {
      "HOME" => @home, "XDG_CONFIG_HOME" => "#{@home}/.config",
      "XDG_DATA_HOME" => "#{@home}/.local/share", "XDG_STATE_HOME" => "#{@home}/.local/state",
      "LACOLD_STATE_HOME" => "#{@home}/state", "CODEX_HOME" => "#{@home}/.codex",
      "BAT_CONFIG_DIR" => "#{@home}/.config/bat", "LACOLD_SKIP_RELOAD" => "1",
      "LACOLD_APPEARANCE" => "dark", "PATH" => "#{File.dirname(RbConfig.ruby)}:#{ENV.fetch('PATH')}"
    }
    @previous = @environment.to_h { |key, _| [key, ENV[key]] }
    ENV.update(@environment)
  end

  def teardown
    @previous.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
    FileUtils.remove_entry(@home)
  end

  def run_lacold(*args, success: true)
    output, errors = StringIO.new, StringIO.new
    status = Lacold::Shell.run(args, out: output, err: errors)
    assert_equal(success ? 0 : 1, status, errors.string)
    success ? output.string : errors.string
  end

  def write(path, content)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  def state
    JSON.parse(File.read("#{@home}/state/state.json"))
  end

  def test_source_and_list_do_not_write_configuration
    output = run_lacold("list")
    Lacold::Adapters.ids.each { |id| assert_includes output, id }
    assert_includes run_lacold("show", "codex"), "accent_primary"
    refute File.exist?("#{@home}/state")
  end

  def test_all_targets_install_switch_override_and_remove_restore_originals
    original = "# user options\n[tui]\nnotifications = false\ntheme = 'other'\n\n[projects]\n"
    write("#{@home}/.codex/config.toml", original)
    run_lacold("install", "all", "--color", "orange")
    assert_equal Lacold::Adapters.ids.sort, state.fetch("items").keys.sort
    assert_includes File.read("#{@home}/.codex/config.toml"), 'theme = "lacold-orange-dark"'
    assert_equal 0o600, File.stat("#{@home}/state/state.json").mode & 0o777
    run_lacold("use", "all", "pink", "light")
    assert_includes File.read("#{@home}/.config/kitty/dark-theme.auto.conf"), "Lacold Pink Light"
    run_lacold("set", "all", "bg", "#112233", "--mode", "dark")
    assert_includes File.read("#{@home}/.config/kitty/themes/lacold-pink-dark.conf"), "background #112233"
    refute_includes File.read("#{@home}/.config/kitty/themes/lacold-pink-light.conf"), "background #112233"
    run_lacold("reset", "all", "bg")
    refute_includes File.read("#{@home}/.config/kitty/themes/lacold-pink-dark.conf"), "background #112233"
    run_lacold("remove", "all")
    assert_empty state.fetch("items")
    assert_empty state.fetch("files")
    assert_equal original, File.read("#{@home}/.codex/config.toml")
    refute File.exist?("#{@home}/.config/kitty/themes/lacold-pink-dark.conf")
  end

  def test_invalid_request_and_external_edits_leave_all_files_unchanged
    run_lacold("install", "kitty")
    original_state = File.read("#{@home}/state/state.json")
    original_theme = File.read("#{@home}/.config/kitty/themes/lacold-blue-dark.conf")
    run_lacold("set", "kitty", "bg", "$(touch bad)", success: false)
    run_lacold("set", "kitty", "nonsense", "#123456", success: false)
    run_lacold("use", "all", "missing", success: false)
    path = "#{@home}/.config/kitty/kitty.conf"
    File.open(path, "a") { |file| file.puts "# user edit" }
    assert_includes run_lacold("use", "kitty", "green", success: false), "changed outside lacold"
    assert_includes run_lacold("remove", "kitty", success: false), "preserved modified file"
    assert_equal original_state, File.read("#{@home}/state/state.json")
    assert_equal original_theme, File.read("#{@home}/.config/kitty/themes/lacold-blue-dark.conf")
    assert_includes File.read(path), "# user edit"
  end

  def test_migration_is_bounded_idempotent_and_retains_backups
    old = "#{@home}/.config/emacs/user-lisp/workbench/themes/lacold-air-blue-light-theme.el"
    write(old, "(deftheme lacold-air-blue-light)\n(provide-theme 'lacold-air-blue-light)\n")
    write("#{old}c", "\x00compiled lacold-air-blue-light\xFF".b)
    write("#{@home}/.config/vim/colors/lacold-blue.vim", "let g:colors_name = 'lacold-blue'\n")
    config = "#{@home}/.config/vim/config/colors.vim"
    write(config, "vim9script\nexecute 'colorscheme lacold-air-blue-' .. mode\n")
    untouched = "#{@home}/.config/unrelated.txt"
    write(untouched, "lacold-air-blue-dark")
    assert_includes run_lacold("migrate", "--dry-run"), "Would migrate"
    assert File.file?(old)
    refute File.exist?("#{@home}/state/state.json")
    run_lacold("migrate")
    renamed = old.sub("lacold-air-", "lacold-")
    assert File.file?(renamed)
    refute File.exist?(old)
    refute File.exist?("#{old}c")
    refute File.exist?("#{renamed}c"), "compiled bytes must never be text-rewritten"
    assert_includes File.read(renamed), "deftheme lacold-blue-light"
    assert_includes File.read(config), "&background = mode\n    colorscheme lacold-blue"
    assert_equal "lacold-air-blue-dark", File.read(untouched)
    assert state.fetch("migrations").fetch(old).fetch("original")
    refute_includes run_lacold("migrate"), "Migrate:"
    run_lacold("install", "emacs")
    run_lacold("remove", "emacs")
    assert File.file?(renamed), "removal must restore migrated themes"
  end

  def test_migration_collision_aborts_before_writing
    directory = "#{@home}/.config/kitty/themes"
    write("#{directory}/lacold-air-blue-dark.conf", "old")
    write("#{directory}/lacold-blue-dark.conf", "different")
    assert_includes run_lacold("migrate", success: false), "collision"
    assert_equal "old", File.read("#{directory}/lacold-air-blue-dark.conf")
    refute File.exist?("#{@home}/state/state.json")
  end

  def test_three_shells_keep_session_state_and_restore_options
    root = File.expand_path("..", __dir__)
    %w[bash zsh fish].each do |shell|
      flags = shell == "fish" ? ["--no-config"] : shell == "zsh" ? ["-f"] : ["--noprofile", "--norc"]
      script = if shell == "fish"
        <<~FISH
          set -gx FZF_DEFAULT_OPTS '--height=40% --bind="ctrl-x:abort"'
          set -gx BAT_THEME original
          source #{Shellwords.escape("#{root}/lacold.fish")}
          lacold install fzf --color orange
          lacold install bat
          lacold use fzf pink light
          lacold reload fzf
          echo OPTIONS:$FZF_DEFAULT_OPTS
          echo BAT:$BAT_THEME
          lacold remove all
          echo RESTORED:$FZF_DEFAULT_OPTS
          echo BATRESTORED:$BAT_THEME
          functions -q lacold
        FISH
      else
        <<~SH
          export FZF_DEFAULT_OPTS='--height=40% --bind="ctrl-x:abort"'
          export BAT_THEME=original
          source #{Shellwords.escape("#{root}/lacold.#{shell}")}
          lacold install fzf --color orange
          lacold install bat
          lacold use fzf pink light
          lacold reload fzf
          echo "OPTIONS:$FZF_DEFAULT_OPTS"
          echo "BAT:$BAT_THEME"
          lacold remove all
          echo "RESTORED:$FZF_DEFAULT_OPTS"
          echo "BATRESTORED:$BAT_THEME"
          typeset -f lacold >/dev/null
        SH
      end
      output, errors, status = Open3.capture3(@environment, shell, *flags, "-c", script)
      assert status.success?, "#{shell}: #{errors}\n#{output}"
      assert_empty errors, "#{shell}: #{errors}"
      assert_includes output, 'RESTORED:--height=40% --bind="ctrl-x:abort"'
      assert_includes output, "BAT: lacold-blue-dark".delete(" ")
      assert_includes output, "BATRESTORED:original"
      options = output.lines.find { |line| line.start_with?("OPTIONS:") }
      assert_equal 1, options.scan("--color=").size, "#{shell}: refresh must not accumulate flags"
    end
  end

  def test_fish_native_theme_applies_in_current_session
    root = File.expand_path("..", __dir__)
    script = "set -g fish_color_command ABCDEF --bold; source #{Shellwords.escape("#{root}/lacold.fish")}; lacold install fish --color orange --mode dark; echo COLOR:$fish_color_command; lacold set fish accent_primary '#123456'; echo CHANGED:$fish_color_command; lacold remove fish; echo RESTORED:$fish_color_command"
    output, errors, status = Open3.capture3(@environment, "fish", "--no-config", "-c", script)
    assert status.success?, "#{errors}\n#{output}"
    assert_empty errors
    assert_includes output, "COLOR:D78A50"
    assert_includes output, "CHANGED:123456"
    assert_includes output, "RESTORED:ABCDEF"
  end

  def test_write_failure_rolls_back_generated_files
    FileUtils.mkdir_p("#{@home}/.config/kitty/kitty.conf")
    run_lacold("install", "kitty", success: false)
    refute File.exist?("#{@home}/state/state.json")
    assert_empty Dir.glob("#{@home}/state/themes/kitty/**/*.conf")
    assert_empty Dir.glob("#{@home}/.config/kitty/themes/**/*.conf")
  end

  def test_vim9_startup_uses_valid_comments_and_loads_selected_family
    startup = "#{@home}/.config/vim/vimrc"
    write(startup, "vim9script\nset background=light\n")
    run_lacold("install", "vim", "--color", "green", "--mode", "auto")
    assert_includes File.read(startup), "# >>> lacold vim >>>"
    script = "#{@home}/verify.vim"
    output = "#{@home}/vim-result"
    write(script, "vim9script\nwritefile([g:colors_name, &background], #{output.inspect})\nqa!\n")
    runtime = "#{@home}/.config/vim"
    _out, errors, status = Open3.capture3("vim", "-N", "--not-a-term", "-es", "--cmd", "set runtimepath^=#{runtime.gsub(' ', '\\ ')}", "-u", startup, "-S", script)
    assert status.success?, errors
    assert_equal ["lacold-green", "light"], File.readlines(output, chomp: true)
  end

  def test_install_adopts_configured_color_and_mode
    path = "#{@home}/.codex/config.toml"
    write(path, "[tui]\ntheme = 'lacold-orange-light'\n")
    assert_includes run_lacold("list"), "orange/light"
    assert_includes run_lacold("show", "codex"), "configured variant"
    run_lacold("install", "codex")
    assert_equal "orange", state.fetch("items").fetch("codex").fetch("color")
    assert_equal "light", state.fetch("items").fetch("codex").fetch("mode")
  end

  def test_codex_table_without_final_newline_is_updated
    path = "#{@home}/.codex/config.toml"
    write(path, "[tui]")
    run_lacold("install", "codex")
    assert_includes File.read(path), 'theme = "lacold-blue-dark"'
  end

  def test_jsonc_changes_root_property_and_preserves_comments_and_nested_settings
    original = <<~JSONC
      {
        // personal preference
        "nested": {"theme": "keep", "url": "https://example.com"},
        "theme": {"mode": "system", "dark": "old"}, // keep this comment
      }
    JSONC
    updated = Lacold::JSONSettings.set(original, "theme", "Lacold Blue Dark")
    assert_includes updated, '"theme": "keep"'
    assert_includes updated, '"theme": "Lacold Blue Dark", // keep this comment'
    assert_includes updated, "// personal preference"
    inserted = Lacold::JSONSettings.set("{\"x\": [1, {\"a\": true} ] // comment\n}\n", "theme", "new")
    assert_includes inserted, '], // comment'
  end
end
