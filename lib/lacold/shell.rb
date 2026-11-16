# frozen_string_literal: true

# The sourceable shell functions are the public interface. Reuse the generator
# here rather than shipping three divergent implementations of every adapter.
require_relative "../lacold"
require "shellwords"
require "tmpdir"
require "tempfile"
require "open3"
require_relative "json_settings"

module Lacold
  class Shell
    MODES = %w[light dark auto].freeze
    MUTATIONS = %w[install use set reset remove reload migrate].freeze

    def self.run(arguments, out: $stdout, err: $stderr)
      if MUTATIONS.include?(arguments.first) && !arguments.include?("--dry-run")
        root = ENV.fetch("LACOLD_STATE_HOME", "#{ENV.fetch('XDG_STATE_HOME', "#{ENV.fetch('HOME')}/.local/state")}/lacold")
        FileUtils.mkdir_p(root, mode: 0o700)
        File.open("#{root}/lock", File::RDWR | File::CREAT, 0o600) do |lock|
          lock.flock(File::LOCK_EX)
          new(out: out, err: err).run(arguments.dup)
        end
      else
        new(out: out, err: err).run(arguments.dup)
      end
    rescue Error, OptionParser::ParseError, SystemCallError, JSON::ParserError => error
      err.puts "lacold: #{error.message}"
      1
    end

    def initialize(out:, err:)
      @out, @err = out, err
      @home = File.expand_path(ENV.fetch("HOME"))
      @config = File.expand_path(ENV.fetch("XDG_CONFIG_HOME", "#{@home}/.config"))
      @data = File.expand_path(ENV.fetch("XDG_DATA_HOME", "#{@home}/.local/share"))
      @root = File.expand_path(ENV.fetch("LACOLD_STATE_HOME", "#{ENV.fetch('XDG_STATE_HOME', "#{@home}/.local/state")}/lacold"))
      @state_path = "#{@root}/state.json"
      @state = File.file?(@state_path) ? JSON.parse(File.read(@state_path)) : {"items" => {}, "files" => {}}
      @plan = {}
    end

    def run(args)
      command = args.shift || "list"
      case command
      when "help", "--help", "-h" then @out.puts help
      when "list", "status" then no_args!(args); list
      when "variants" then no_args!(args); @out.puts "Colors: #{Lacold.colors.join(', ')}\nModes: #{MODES.join(', ')}"
      when "show" then show(args)
      when "install", "use", "set", "reset", "remove", "reload"
        mutate(command, args)
      when "migrate" then migrate(args)
      when "_session" then session(args)
      else raise Error, "unknown command: #{command}; run lacold help"
      end
      0
    end

    private

    def help
      <<~HELP
        lacold — source lacold.fish, lacold.bash, or lacold.zsh first

        lacold list                            All targets, installed files, selection
        lacold variants                        Available colors and modes
        lacold show [ITEM]                      Effective palette roles and hex colors
        lacold install ITEM|all [--color blue] [--mode auto]
        lacold use ITEM|all COLOR [light|dark|auto]
        lacold set ITEM|all ROLE '#RRGGBB' [--mode light|dark]
        lacold reset ITEM|all [ROLE]            Remove color overrides
        lacold reload [ITEM|all]                Regenerate managed themes
        lacold remove ITEM|all                  Restore files changed by install
        lacold migrate [--dry-run]              Rename legacy Lacold Air files/references

        use/set/reset/reload all affect managed items only; install all installs all
        27 targets. Import-only targets are staged with native instructions.
        auto uses native adaptive files where supported; other apps need reload.
        set without --mode changes both light and dark palettes. Overrides are local.
        State/backups: #{@root}
      HELP
    end

    def no_args!(args)
      raise Error, "unexpected arguments: #{args.join(' ')}" unless args.empty?
    end

    def item_ids(value, installed: false)
      if value == "all"
        ids = installed ? @state.fetch("items").keys : Adapters.ids
        raise Error, "no managed items; run lacold install ITEM first" if ids.empty?
        ids
      else
        [Adapters.find(value).id]
      end
    end

    def profile(id)
      @state.fetch("items")[id] || configured_profile(id) || {"color" => "blue", "mode" => "auto", "overrides" => {}}
    end

    def configured_profile(id)
      files = reference_files(id).select { |path| File.file?(path) }
      values = files.filter_map do |path|
        content = File.read(path)
        case id
        when "codex"
          table = content[/^\[tui\][^\n]*\n(.*?)(?=^\[|\z)/m, 1]
          table && table[/^theme\s*=\s*["']([^"']+)["']/, 1]
        when "fish" then content[/^\s*fish_config theme choose\s+["']?([\w-]+)/, 1]
        when "vim" then content[/\bcolorscheme\s+(lacold-[\w-]+)/, 1]
        when "emacs" then content[/\(workbench-(?:lacold-)?theme\s+'(lacold-[\w-]+)/, 1]
        when "kitty" then content[/Lacold(?: Air)? \w+ (?:Light|Dark)/]
        when "vscode", "zed", "opencode"
          JSONSettings.string(content, id == "vscode" ? "workbench.colorTheme" : "theme") unless content.strip.empty?
        else content[/lacold-(?:air-)?(?:blue|green|orange|pink|purple|rainbow)(?:-(?:light|dark))?/i]
        end
      end
      matches = values.filter_map { |value| value.match(/\Alacold[- ](?:air[- ])?(blue|green|orange|pink|purple|rainbow)(?:[- ](light|dark))?/i) }
      return if matches.empty?
      # Multiple colors in a config are ambiguous; expose references in show.
      return unless matches.map { |match| match[1].downcase }.uniq.size == 1
      modes = matches.map { |match| match[2]&.downcase }.compact.uniq
      {"color" => matches.first[1].downcase, "mode" => modes.size == 1 ? modes.first : "auto", "overrides" => {}}
    rescue Error, JSON::ParserError, Errno::EACCES, Errno::EPERM
      nil
    end

    def library
      "#{@root}/themes"
    end

    # Explicit, bounded directories only. Never walk HOME or an entire config tree.
    def destinations(id)
      mac = "#{@home}/Library"
      case id
      when "fish" then [["fish/themes/", "#{@config}/fish/themes"]]
      when "vim"
        paths = [File.directory?("#{@config}/vim") ? "#{@config}/vim/colors" : "#{@home}/.vim/colors"]
        paths << "#{@config}/nvim/colors" if File.directory?("#{@config}/nvim")
        paths.map { |path| ["vim/colors/", path] }
      when "emacs"
        path = "#{@config}/emacs/user-lisp/workbench/themes"
        [["emacs/", File.directory?(path) ? path : "#{@config}/emacs/themes"]]
      when "codex" then [["codex/themes/", "#{ENV.fetch('CODEX_HOME', "#{@home}/.codex")}/themes"]]
      when "kitty" then [["kitty/", "#{@config}/kitty/themes"]]
      when "bat" then [["bat/", "#{ENV.fetch('BAT_CONFIG_DIR', "#{@config}/bat")}/themes"]]
      when "opencode", "zed", "btop", "zellij" then [["#{id}/", "#{@config}/#{id}/themes"]]
      when "xcode" then [["xcode/", "#{mac}/Developer/Xcode/UserData/FontAndColorThemes"]]
      when "coteditor" then [["coteditor/", "#{mac}/Containers/com.coteditor.CotEditor/Data/Library/Application Support/CotEditor/Themes"]]
      when "gedit" then [["gedit/", "#{@data}/gtksourceview-5/styles"]]
      when "kate" then [["kate/", "#{@data}/org.kde.syntax-highlighting/themes"]]
      when "konsole" then [["konsole/", "#{@data}/konsole"]]
      when "vscode" then [["vscode/", "#{@home}/.vscode/extensions/aozy.lacold-theme-#{VERSION}"]]
      else []
      end
    end

    def installed_paths(id)
      paths = destinations(id).flat_map do |_, directory|
        Dir.glob("#{directory}/lacold*") + Dir.glob("#{directory}/Lacold*")
      end
      if id == "vscode"
        paths.concat(Dir.glob("#{@home}/.vscode/extensions/aozy.lacold-theme-*/themes/lacold*.json"))
      end
      paths.select { |path| File.file?(path) }.uniq
    rescue Errno::EACCES, Errno::EPERM
      []
    end

    def list
      @out.puts format("%-17s %-10s %-20s %s", "ITEM", "FILES", "CONFIGURED", "ACTION")
      Adapters.all.each do |adapter|
        id = adapter.id
        managed = @state.fetch("items")[id]
        count = installed_paths(id).size
        count = @state.fetch("files").count { |path, entry| entry["item"] == id && File.file?(path) } if managed
        configured = managed || configured_profile(id)
        selection = configured ? "#{configured.fetch('color')}/#{configured.fetch('mode')}#{managed ? ' *' : ''}" : "unknown"
        @out.puts format("%-17s %-10s %-20s %s", id, count.zero? ? "—" : count, selection, activation_note(id))
      end
      @out.puts "* managed. Other selections come from named config files; runtime appearance may differ. lacold show ITEM lists references."
    end

    def themes_for(id)
      p = profile(id)
      Lacold.themes(colors: [p.fetch("color")]).map do |theme|
        groups = %i[neutrals accent semantics spectrum syntax].to_h { |group| [group, theme.public_send(group).dup] }
        p.fetch("overrides").fetch(theme.mode.to_s, {}).each do |role, hex|
          group, key = role_location(theme, role)
          groups.fetch(group)[key] = hex
        end
        Theme.new(background: theme.background, color: theme.color, mode: theme.mode, **groups)
      end
    end

    def role_location(theme, role)
      # Prefer the unambiguous public names from Theme#colors.
      {"accent_" => :accent, "semantic_" => :semantics, "spectrum_" => :spectrum, "syntax_" => :syntax}.each do |prefix, group|
        next unless role.start_with?(prefix)
        key = role.delete_prefix(prefix).to_sym
        return [group, key] if theme.public_send(group).key?(key) || (group == :syntax && SYNTAX_ROLES.include?(key))
      end
      return [:neutrals, role.to_sym] if theme.neutrals.key?(role.to_sym)
      raise Error, "unknown role: #{role}; run lacold show ITEM"
    end

    SYNTAX_ROLES = %i[keyword type builtin function string regexp constant label symbol number tag attribute decorator macro preprocessor property escape variable operator punctuation link].freeze

    def show(args)
      id = Adapters.find(args.shift || "fish").id
      no_args!(args)
      source = @state.fetch('items').key?(id) ? 'managed palette' : configured_profile(id) ? 'configured variant; generated palette preview' : 'default preview; current selection unknown'
      @out.puts "#{id}: #{profile(id).fetch('color')}/#{profile(id).fetch('mode')} (#{source})"
      @out.puts format("%-30s %-10s %s", "ROLE", "LIGHT", "DARK")
      light, dark = themes_for(id)
      light.colors.merge(dark.colors).keys.each do |key|
        @out.puts format("%-30s %-10s %s", key, light.colors[key] || "—", dark.colors[key] || "—")
      end
      @out.puts "Syntax overrides also accept: #{SYNTAX_ROLES.map { |key| "syntax_#{key}" }.join(', ')}"
      installed_paths(id).each { |path| @out.puts "File: #{path}" }
      reference_files(id).each do |path|
        next unless File.file?(path)
        File.foreach(path).with_index(1) do |line, number|
          # Print theme identifiers only: a matching line may contain credentials.
          names = line.scan(/lacold[- ][a-zA-Z-]+/i).uniq
          @out.puts "Reference: #{path}:#{number}: #{names.join(', ')}" unless names.empty?
        end
      end
    end

    def mutate(command, args)
      target = args.shift || (command == "reload" ? "all" : nil)
      raise Error, "#{command} requires ITEM or all" unless target
      ids = item_ids(target, installed: command != "install")
      options = {}
      parser = OptionParser.new do |opts|
        opts.on("--color COLOR") { |value| options["color"] = value }
        opts.on("--mode MODE") { |value| options["mode"] = value }
      end
      parser.parse!(args)
      case command
      when "use"
        options["color"] = args.shift || raise(Error, "use requires COLOR")
        options["mode"] = args.shift if args.any?
      when "set"
        role, hex = args.shift, args.shift
        raise Error, "set requires ROLE and '#RRGGBB'" unless role && hex&.match?(/\A#[0-9a-fA-F]{6}\z/)
        raise Error, "set --mode accepts light or dark" if options["mode"] && !%w[light dark].include?(options["mode"])
      when "reset" then role = args.shift
      end
      no_args!(args)
      raise Error, "unknown color: #{options['color']}" if options["color"] && !Lacold.colors.include?(options["color"])
      raise Error, "unknown mode: #{options['mode']}" if options["mode"] && !MODES.include?(options["mode"])
      ids.each do |id|
        if command != "install" && !@state.fetch("items").key?(id)
          raise Error, "#{id} is unmanaged; run lacold install #{id} first"
        end
        if command == "remove"
          remove_item(id)
          next
        end
        p = profile(id)
        @state.fetch("items")[id] = p
        case command
        when "set"
          role_location(themes_for(id).first, role)
          (options["mode"] ? [options["mode"]] : %w[light dark]).each do |mode|
            (p.fetch("overrides")[mode] ||= {})[role] = hex.upcase
          end
        when "reset"
          role_location(themes_for(id).first, role) if role
          p.fetch("overrides").each_value { |values| role ? values.delete(role) : values.clear }
        else p.merge!(options)
        end
        generate(id)
      end
      commit!
      if ids.include?("bat") && ENV.fetch("LACOLD_SKIP_RELOAD", "") != "1"
        begin
          _output, errors, status = Open3.capture3("bat", "cache", "--build")
          @err.puts "lacold: bat cache rebuild failed; run bat cache --build (#{errors.strip})" unless status.success?
        rescue Errno::ENOENT
          @err.puts "lacold: run bat cache --build after installing bat"
        end
      end
      ids.each { |id| @out.puts "#{command}: #{id}#{command == 'remove' ? '' : " #{profile(id).fetch('color')}/#{profile(id).fetch('mode')} — #{activation_note(id)}"}" }
      @out.puts "Backups: #{@state_path}"
    end

    def selected(id)
      p = profile(id)
      family = "lacold-#{p.fetch('color')}"
      p.fetch("mode") == "auto" && %w[fish vim iterm2 opencode].include?(id) ? family : "#{family}-#{resolved_mode(id)}"
    end

    def resolved_mode(id)
      mode = profile(id).fetch("mode")
      return mode unless mode == "auto"
      ENV["LACOLD_APPEARANCE"] == "light" ? "light" : "dark"
    end

    def generate(id)
      themes = themes_for(id)
      # Install the entire family, including both explicit modes. Switching mode
      # must not silently remove a theme another window is currently using.
      adapter = Adapters.find(id)
      outputs = (adapter.render(themes) + themes.flat_map { |theme| adapter.render([theme]) }).uniq { |item| item.path }
      outputs.each do |item|
        manage("#{library}/#{item.path}", item.content, id)
        destinations(id).each do |prefix, directory|
          next unless item.path.start_with?(prefix)
          relative = item.path.delete_prefix(prefix)
          next if relative == "README.md" && id != "vscode"
          manage("#{directory}/#{relative}", item.content, id)
        end
      end
      activate(id)
    end

    def activation_note(id)
      case id
      when "fish" then "current Fish + new shells"
      when "fzf", "bat" then "current shell + sourced new shells"
      when "kitty" then "config ready; reload Kitty config"
      when "vim" then "restart Vim or source lacold.vim"
      when "emacs" then "restart Emacs or load lacold.el"
      when "codex", "opencode", "zed", "vscode", "btop", "zellij", "tmux", "nano" then "config ready; reload/restart app"
      when "xcode", "coteditor", "gedit", "kate", "konsole" then "installed; choose in app settings"
      else "import required: #{library}/#{id}/README.md"
      end
    end

    def activate(id)
      name = selected(id)
      color = profile(id).fetch("color")
      mode = resolved_mode(id)
      case id
      when "kitty"
        if profile(id).fetch("mode") == "auto"
          %w[light dark no-preference].each do |appearance|
            source = "#{library}/kitty/auto/lacold-#{color}/#{appearance}-theme.auto.conf"
            manage("#{@config}/kitty/#{appearance}-theme.auto.conf", planned_read(source), id)
          end
          block("#{@config}/kitty/kitty.conf", "", id)
        else
          # Kitty loads auto files after kitty.conf. Pin all three to the same
          # selected palette so a later appearance notification cannot undo use.
          content = planned_read("#{library}/kitty/#{name}.conf")
          %w[light dark no-preference].each { |appearance| manage("#{@config}/kitty/#{appearance}-theme.auto.conf", content, id) }
          block("#{@config}/kitty/kitty.conf", "include themes/#{name}.conf", id)
        end
      when "codex"
        path = "#{ENV.fetch('CODEX_HOME', "#{@home}/.codex")}/config.toml"
        content = read(path)
        content += "\n" unless content.end_with?("\n")
        if content.match?(/^\[tui\][ \t]*(?:#.*)?$/)
          content = content.sub(/(^\[tui\][^\n]*\n)(.*?)(?=^\[|\z)/m) do
            header, body = Regexp.last_match(1), Regexp.last_match(2)
            line = "theme = #{name.inspect}"
            body.match?(/^theme\s*=/) ? header + body.sub(/^theme\s*=.*$/, line) : header + line + "\n" + body
          end
        else
          raise Error, "unsupported inline/quoted tui table in #{path}" if content.match?(/^(?:tui\s*=|\[.?tui)/)
          content = content.rstrip + "\n\n[tui]\ntheme = #{name.inspect}\n"
        end
        manage(path, content, id)
      when "tmux" then block("#{@home}/.tmux.conf", "source-file #{("#{library}/tmux/#{name}.conf").inspect}", id)
      when "nano" then block("#{@home}/.nanorc", "include #{("#{library}/nano/#{name}.nanorc").inspect}", id)
      when "bat"
        block("#{ENV.fetch('BAT_CONFIG_DIR', "#{@config}/bat")}/config", "--theme=#{name}", id)
      when "vim"
        startup = "#{@config}/vim/vimrc"
        startup = "#{@home}/.vimrc" unless File.file?(startup)
        snippet = profile(id).fetch("mode") == "auto" ? "colorscheme #{name}" : "set background=#{mode}\ncolorscheme #{name}"
        manage("#{library}/vim/lacold.vim", snippet + "\n", id)
        loader = "source #{("#{library}/vim/lacold.vim").gsub(/([ \\|])/) { |char| "\\#{char}" }}"
        body = "#{loader}\naugroup LacoldManaged\n  autocmd!\n  autocmd GUIEnter * #{loader}\n  if exists('##OSAppearanceChanged')\n    autocmd OSAppearanceChanged * #{loader}\n  endif\naugroup END"
        block(startup, body, id, marker: read(startup).start_with?("vim9script") ? "#" : '"')
        nvim = "#{@config}/nvim/init.vim"
        block(nvim, body, id, marker: '"') if File.file?(nvim)
        lua = "#{@config}/nvim/init.lua"
        block(lua, "vim.cmd('source ' .. vim.fn.fnameescape(#{("#{library}/vim/lacold.vim").inspect}))", id, marker: "--") if File.file?(lua)
      when "emacs"
        directory = destinations(id).first.last
        snippet = "(add-to-list 'custom-theme-load-path #{directory.inspect})\n(when (boundp 'workbench-lacold-theme) (setq workbench-lacold-theme '#{name}))\n(mapc #'disable-theme custom-enabled-themes)\n(load-theme '#{name} t)\n"
        manage("#{library}/emacs/lacold.el", snippet, id)
        init = "#{@config}/emacs/init.el"
        init = "#{@home}/.emacs.d/init.el" unless File.file?(init)
        block(init, "(load #{("#{library}/emacs/lacold.el").inspect} nil t)", id, marker: ";;")
      when "btop"
        block("#{@config}/btop/btop.conf", "color_theme = #{name.inspect}", id)
      when "zellij"
        # KDL disallows duplicate top-level theme nodes.
        path = "#{@config}/zellij/config.kdl"
        content = read(path)
        line = "theme #{name.inspect}"
        content = content.match?(/^theme\s+"[^"]*"[ \t]*$/) ? content.sub(/^theme\s+"[^"]*"[ \t]*$/, line) : content.rstrip + "\n#{line}\n"
        manage(path, content, id)
      when "zed", "opencode", "vscode"
        path = case id
        when "vscode" then RUBY_PLATFORM.include?("darwin") ? "#{@home}/Library/Application Support/Code/User/settings.json" : "#{@config}/Code/User/settings.json"
        when "opencode" then File.file?("#{@config}/opencode/opencode.jsonc") ? "#{@config}/opencode/opencode.jsonc" : "#{@config}/opencode/opencode.json"
        else "#{@config}/zed/settings.json"
        end
        key = id == "vscode" ? "workbench.colorTheme" : "theme"
        value = %w[vscode zed].include?(id) ? "Lacold #{color.capitalize} #{mode.capitalize}" : name
        json_setting(path, key, value, id)
      end
    end

    def json_setting(path, key, value, id)
      manage(path, JSONSettings.set(read(path).strip.empty? ? "{}\n" : read(path), key, value), id)
    end

    def block(path, body, id, marker: "#")
      content = read(path)
      first, last = "#{marker} >>> lacold #{id} >>>", "#{marker} <<< lacold #{id} <<<"
      pattern = /#{Regexp.escape(first)}\n.*?#{Regexp.escape(last)}\n?/m
      replacement = "#{first}\n#{body}\n#{last}\n"
      content = content.match?(pattern) ? content.sub(pattern, replacement) : content + (content.end_with?("\n") || content.empty? ? "" : "\n") + replacement
      manage(path, content, id)
    end

    def read(path)
      @plan.key?(path) ? (@plan[path] || "") : (File.file?(path) ? File.binread(path) : "")
    end

    def planned_read(path)
      @plan.fetch(path) { File.binread(path) }
    end

    def manage(path, content, id)
      entry = @state.fetch("files")[path]
      current = File.file?(path) ? File.binread(path) : nil
      if entry && current && Digest::SHA256.hexdigest(current) != entry.fetch("sha256")
        raise Error, "changed outside lacold: #{path}; keep your edits or restore from #{@state_path} before retrying"
      end
      @state.fetch("files")[path] ||= {
        "item" => id, "original" => current && [current].pack("m0"),
        "mode" => File.file?(path) ? File.stat(path).mode & 0o777 : 0o600
      }
      @state.fetch("files")[path]["sha256"] = Digest::SHA256.hexdigest(content)
      @plan[path] = content
    end

    def remove_item(id)
      @state.fetch("files").select { |_, entry| entry.fetch("item") == id }.each do |path, entry|
        if File.file?(path) && Digest::SHA256.file(path).hexdigest != entry.fetch("sha256")
          raise Error, "preserved modified file: #{path}; remove aborted (backup: #{@state_path})"
        end
        @plan[path] = entry["original"] && entry.fetch("original").unpack1("m0")
        @state.fetch("files").delete(path)
      end
      @state.fetch("items").delete(id)
    end

    # Validate everything before writing and roll back file contents on failure.
    # The state file is private because originals can contain private settings.
    def commit!
      originals = @plan.keys.to_h { |path| [path, File.file?(path) ? [File.binread(path), File.stat(path).mode & 0o777] : nil] }
      @plan.each do |path, content|
        if content.nil?
          File.unlink(path) if File.file?(path)
        else
          mode = @state.fetch("files").dig(path, "mode") || originals.dig(path, 1) || 0o600
          atomic_write(path, content, mode)
        end
      end
      atomic_write(@state_path, JSON.pretty_generate(@state) + "\n", 0o600)
    rescue StandardError
      originals&.each do |path, entry|
        entry ? atomic_write(path, entry[0], entry[1]) : (File.unlink(path) if File.file?(path))
      end
      raise
    end

    def atomic_write(path, content, mode)
      FileUtils.mkdir_p(File.dirname(path))
      # Follow an existing file symlink, keeping dotfile repositories connected.
      path = File.realpath(path) if File.symlink?(path)
      Tempfile.create([".lacold-", ".tmp"], File.dirname(path)) do |file|
        file.binmode
        file.write(content)
        file.chmod(mode)
        file.close
        File.rename(file.path, path)
      end
    end

    def reference_files(id)
      paths = case id
      when "fish" then ["#{@config}/fish/config.fish"]
      when "kitty" then %w[kitty.conf light-theme.auto.conf dark-theme.auto.conf no-preference-theme.auto.conf].map { |name| "#{@config}/kitty/#{name}" }
      when "vim" then ["#{@home}/.vimrc", "#{@config}/vim/vimrc", "#{@config}/vim/config/core.vim", "#{@config}/vim/config/colors.vim", "#{@config}/nvim/init.vim", "#{@config}/nvim/init.lua"]
      when "emacs" then ["#{@config}/emacs/init.el", "#{@config}/emacs/custom.el", "#{@config}/emacs/user-lisp/workbench/editor-ui.el", "#{@config}/emacs/theme.local", "#{@home}/.emacs.d/init.el"]
      when "codex" then ["#{ENV.fetch('CODEX_HOME', "#{@home}/.codex")}/config.toml"]
      when "vscode" then ["#{@home}/Library/Application Support/Code/User/settings.json", "#{@config}/Code/User/settings.json"]
      when "tmux" then ["#{@home}/.tmux.conf"]
      when "nano" then ["#{@home}/.nanorc"]
      when "btop" then ["#{@config}/btop/btop.conf"]
      when "zellij" then ["#{@config}/zellij/config.kdl"]
      else ["#{@config}/#{id}/config", "#{@config}/#{id}/settings.json", "#{@config}/#{id}/#{id}.json", "#{@config}/#{id}/#{id}.jsonc"]
      end
      paths.uniq
    end

    def migrate(args)
      dry_run = args.delete("--dry-run")
      no_args!(args)
      rename = ->(value) { value.gsub(/lacold-air-/i, 'lacold-').gsub(/Lacold Air\b/, 'Lacold') }
      Adapters.ids.each do |id|
        (installed_paths(id) + reference_files(id)).uniq.each do |path|
          next unless File.file?(path)
          original = File.binread(path)
          if path.end_with?(".elc")
            next unless path.include?("lacold-air-")
            @out.puts "#{dry_run ? 'Would remove stale bytecode' : 'Remove stale bytecode'}: #{path}"
            unless dry_run
              migration_backup(path)
              @plan[path] = nil
            end
            next
          end
          content = rename.call(original)
          if id == "vim" && reference_files(id).include?(path)
            # A previous install supplied adaptive family files but its Vim9
            # loader still requested nonexistent mode-specific schemes.
            content = content.gsub(/execute 'colorscheme lacold-(\w+)-' \.\. mode/) do
              family = Regexp.last_match(1)
              "&background = mode\n    colorscheme lacold-#{family}"
            end
            content = content.gsub(/\bcolorscheme lacold-(\w+)-(?:light|dark)\b/) do |match|
              family = "lacold-#{Regexp.last_match(1)}"
              installed_paths(id).any? { |file| File.basename(file) == "#{family}.vim" } ? "colorscheme #{family}" : match
            end
          end
          # These labels are specific to the known Emacs Lacold selector.
          if path.end_with?("/workbench/editor-ui.el")
            content = content.gsub(/(:tag ")Air (Blue|Green|Orange|Pink|Purple|Rainbow)/, '\1\2')
          end
          destination = File.join(File.dirname(path), rename.call(File.basename(path)))
          next if content == original && destination == path
          if destination != path && File.exist?(destination) && File.binread(destination) != content
            raise Error, "migration collision: #{destination}; no files changed"
          end
          @out.puts "#{dry_run ? 'Would migrate' : 'Migrate'}: #{path}#{destination == path ? '' : " → #{destination}"}"
          next if dry_run
          # Migration has its own ownership, so removing a theme does not undo
          # references to the current public name. Backups remain reversible.
          [path, destination].uniq.each do |file|
            migration_backup(file)
          end
          @plan[destination] = content
          if path.end_with?(".el") && File.file?("#{path}c")
            migration_backup("#{path}c")
            @plan["#{path}c"] = nil
          end
          if destination != path
            @plan[path] = nil
          end
        end
      end
      commit! unless dry_run || @plan.empty?
      @out.puts "Migration scope: known theme directories and named config files only."
    end

    def migration_backup(path)
      @state["migrations"] ||= {}
      @state["migrations"][path] ||= {
        "original" => File.file?(path) ? [File.binread(path)].pack("m0") : nil,
        "mode" => File.file?(path) ? File.stat(path).mode & 0o777 : 0o600
      }
    end

    def session(args)
      shell = args.shift
      no_args!(args)
      raise Error, "unknown shell" unless %w[fish bash zsh].include?(shell)
      quote = ->(value) { "'#{value.gsub("\\") { "\\\\" }.gsub("'") { "\\'" }}'" }
      assign = lambda do |key, value|
        @out.puts(shell == "fish" ? "set -gx #{key} #{quote.call(value)}" : "export #{key}=#{Shellwords.escape(value)}")
      end
      if @state.fetch("items").key?("fzf")
        theme = themes_for("fzf").find { |item| item.mode.to_s == resolved_mode("fzf") }
        snippet = Adapters.find("fzf").render([theme]).find { |item| item.path.end_with?(".sh") }.content
        colors = snippet[/--color=([^"\n]+)/, 1]
        # Each refresh replaces only the suffix added by this shell integration.
        if shell == "fish"
          @out.puts "if not set -q _LACOLD_FZF_SAVED; set -g _LACOLD_FZF_SAVED 1; set -g _LACOLD_FZF_BASE \"$FZF_DEFAULT_OPTS\"; end"
          @out.puts "set -gx FZF_DEFAULT_OPTS \"$_LACOLD_FZF_BASE\"#{quote.call(" #{'--color=' + colors}")}"
        else
          @out.puts 'if [ "${_LACOLD_FZF_SAVED-}" != 1 ]; then _LACOLD_FZF_SAVED=1; _LACOLD_FZF_BASE=${FZF_DEFAULT_OPTS-}; fi'
          @out.puts "export FZF_DEFAULT_OPTS=\"$_LACOLD_FZF_BASE\"#{Shellwords.escape(" --color=#{colors}")}"
        end
      else
        @out.puts(shell == "fish" ? 'if set -q _LACOLD_FZF_SAVED; set -gx FZF_DEFAULT_OPTS "$_LACOLD_FZF_BASE"; set -e _LACOLD_FZF_SAVED; end' : 'if [ "${_LACOLD_FZF_SAVED-}" = 1 ]; then export FZF_DEFAULT_OPTS=$_LACOLD_FZF_BASE; unset _LACOLD_FZF_SAVED; fi')
      end
      if @state.fetch("items").key?("bat")
        if shell == "fish"
          @out.puts 'if not set -q _LACOLD_BAT_SAVED; set -g _LACOLD_BAT_SAVED 1; set -g _LACOLD_BAT_BASE "$BAT_THEME"; end'
        else
          @out.puts 'if [ "${_LACOLD_BAT_SAVED-}" != 1 ]; then _LACOLD_BAT_SAVED=1; _LACOLD_BAT_BASE=${BAT_THEME-}; fi'
        end
        assign.call("BAT_THEME", selected("bat"))
      else
        @out.puts(shell == "fish" ? 'if set -q _LACOLD_BAT_SAVED; set -gx BAT_THEME "$_LACOLD_BAT_BASE"; set -e _LACOLD_BAT_SAVED; end' : 'if [ "${_LACOLD_BAT_SAVED-}" = 1 ]; then export BAT_THEME=$_LACOLD_BAT_BASE; unset _LACOLD_BAT_SAVED; fi')
      end
      if shell == "fish" && @state.fetch("items").key?("fish")
        @out.puts <<~FISH
          if not set -q _LACOLD_FISH_SAVED
            set -g _LACOLD_FISH_SAVED 1
            set -g _LACOLD_FISH_VARS (set -n | string match -r '^fish_(?:pager_)?color_.*')
            set -g _LACOLD_FISH_HOOK (functions __fish_apply_theme | string collect)
            for lacold_var in $_LACOLD_FISH_VARS
              set -g _LACOLD_SAVED_$lacold_var $$lacold_var
            end
          end
        FISH
        @out.puts "fish_config theme choose #{quote.call(selected('fish'))}"
      elsif shell == "fish"
        @out.puts <<~FISH
          if set -q _LACOLD_FISH_SAVED
            functions -e __fish_apply_theme
            for lacold_var in (set -n | string match -r '^fish_(?:pager_)?color_.*')
              set -eg $lacold_var
            end
            for lacold_var in $_LACOLD_FISH_VARS
              set -l lacold_saved _LACOLD_SAVED_$lacold_var
              set -g $lacold_var $$lacold_saved
              set -e $lacold_saved
            end
            if test -n "$_LACOLD_FISH_HOOK"
              eval $_LACOLD_FISH_HOOK
            end
            set -e _LACOLD_FISH_SAVED
          end
        FISH
      end
    end
  end
end
