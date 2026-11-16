# frozen_string_literal: true

module Lacold
  # A small JSONC parser retaining source offsets. Change a root setting without
  # rewriting comments, unrelated preferences, or formatting in editor configs.
  class JSONSettings
    def self.set(source, key, value)
      new(source).set(key, value)
    end

    def self.string(source, key)
      parser = new(source)
      root = parser.send(:parse_value)
      return unless root[:kind] == :object
      member = root.fetch(:members).find { |item| item[:key] == key }
      return unless member
      node = member.fetch(:value)
      token = source[node[:start]...node[:end]]
      JSON.parse(token) if token.start_with?('"')
    end

    def initialize(source)
      @source = source
      @position = 0
    end

    def set(key, value)
      root = parse_value
      skip_space
      fail_parse unless @position == @source.length && root[:kind] == :object
      matching = root.fetch(:members).select { |member| member[:key] == key }
      raise Error, "duplicate JSON setting: #{key}" if matching.size > 1
      replacement = JSON.generate(value)
      if matching.first
        node = matching.first.fetch(:value)
        @source[0...node[:start]] + replacement + @source[node[:end]..]
      else
        closing = root[:end] - 1
        prefix = @source[0...closing]
        # Place the separator before trailing comments, not after a // comment.
        last = root.fetch(:members).last
        prefix = prefix.dup.insert(last[:value][:end], ",") if last && !root[:trailing_comma]
        prefix + "\n  #{JSON.generate(key)}: #{replacement}\n" + @source[closing..]
      end
    end

    private

    def fail_parse
      raise Error, "unsupported or invalid JSONC settings at offset #{@position}; file left unchanged"
    end

    def skip_space
      loop do
        rest = @source[@position..]
        token = rest[/\A(?:\s+|\/\/[^\n]*(?:\n|\z)|\/\*.*?\*\/)/m]
        break unless token
        @position += token.length
      end
    end

    def parse_value
      skip_space
      start = @position
      node = {start: start}
      case @source[@position]
      when "{"
        node[:kind], node[:members] = :object, []
        @position += 1
        skip_space
        unless @source[@position] == "}"
          loop do
            skip_space
            fail_parse unless @source[@position] == '"'
            key = parse_string
            skip_space
            fail_parse unless @source[@position] == ":"
            @position += 1
            node[:members] << {key: key, value: parse_value}
            skip_space
            break unless @source[@position] == ","
            @position += 1
            skip_space
            if @source[@position] == "}"
              node[:trailing_comma] = true
              break
            end
          end
        end
        fail_parse unless @source[@position] == "}"
        @position += 1
      when "["
        @position += 1
        skip_space
        unless @source[@position] == "]"
          loop do
            parse_value
            skip_space
            break unless @source[@position] == ","
            @position += 1
            skip_space
            break if @source[@position] == "]"
          end
        end
        fail_parse unless @source[@position] == "]"
        @position += 1
      when '"' then parse_string
      else
        token = @source[@position..][/\A(?:true|false|null|-?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE][+-]?\d+)?)/]
        fail_parse unless token
        @position += token.length
      end
      node.merge(end: @position)
    end

    def parse_string
      token = @source[@position..][/\A"(?:[^"\\\x00-\x1f]|\\(?:["\\\/bfnrt]|u[0-9a-fA-F]{4}))*"/]
      fail_parse unless token
      @position += token.length
      JSON.parse(token)
    end
  end
end
