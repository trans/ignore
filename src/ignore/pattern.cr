module Ignore
  # Represents a single gitignore pattern
  class Pattern
    getter pattern : String
    getter base_path : String
    getter? negated : Bool
    getter? directory_only : Bool
    getter? anchored : Bool

    @regex : Regex

    def initialize(pattern : String, base_path : String = "")
      @pattern = pattern
      @base_path = base_path.chomp("/")
      @base_path = @base_path + "/" unless @base_path.empty?
      @negated = false
      @directory_only = false
      @anchored = false

      working = pattern

      # Handle negation (! prefix)
      if working.starts_with?("!") && !working.starts_with?("\\!")
        @negated = true
        working = working[1..]
      elsif working.starts_with?("\\!")
        working = working[1..] # Remove escape, keep !
      end

      # Handle escaped # at start
      if working.starts_with?("\\#")
        working = working[1..] # Remove escape, keep #
      end

      # Handle trailing spaces (remove unless escaped)
      working = remove_trailing_spaces(working)

      # Handle directory-only (trailing /)
      if working.ends_with?("/") && !working.ends_with?("\\/")
        @directory_only = true
        working = working[0..-2]
      end

      # Handle anchoring
      if working.starts_with?("/")
        @anchored = true
        working = working[1..]
      elsif working.includes?("/") && !working.starts_with?("**/")
        # Contains slash (not just trailing, not **/prefix) = anchored
        @anchored = true
      end

      @regex = build_regex(working)
    end

    def matches?(path : String) : Bool
      is_dir = path.ends_with?("/")
      check_path = is_dir ? path[0..-2] : path

      # Directory-only patterns don't match files
      return false if @directory_only && !is_dir

      # If we have a base path, the check_path must be within it
      unless @base_path.empty?
        if check_path.starts_with?(@base_path)
          # Get the relative path for matching
          check_path = check_path[@base_path.size..]
        elsif check_path + "/" == @base_path
          # Path is exactly the base directory itself
          check_path = ""
        else
          return false
        end
      end

      @regex.matches?(check_path)
    end

    private def remove_trailing_spaces(s : String) : String
      result = s
      while result.ends_with?(" ") && !result.ends_with?("\\ ")
        result = result[0..-2]
      end
      # Convert escaped trailing space to regular space
      if result.ends_with?("\\ ")
        result = result[0..-3] + " "
      end
      result
    end

    private def build_regex(pattern : String) : Regex
      regex_str = String.build do |str|
        str << "^"

        # If not anchored, pattern can match at any depth
        unless @anchored
          str << "(.+/)?"
        end

        i = 0
        len = pattern.size

        while i < len
          c = pattern[i]

          case c
          when '\\'
            # Escape: next character is literal
            if i + 1 < len
              i += 1
              str << Regex.escape(pattern[i].to_s)
            end
          when '*'
            if i + 1 < len && pattern[i + 1] == '*'
              # ** - double asterisk
              before_slash = i == 0 || pattern[i - 1] == '/'
              after_slash = i + 2 < len && pattern[i + 2] == '/'
              at_end = i + 2 == len

              if before_slash && after_slash
                # **/ - zero or more directories
                str << "(.+/)?"
                i += 2 # skip **, the / will be skipped by i += 1 at end
              elsif before_slash && at_end
                # ** at end - match everything remaining
                str << ".*"
                i += 1 # skip second *
              elsif i > 0 && pattern[i - 1] == '/' && at_end
                # /** at end - match everything inside
                str << ".*"
                i += 1
              else
                # ** not at path boundary - treat as literal **
                str << "[^/]*[^/]*"
                i += 1
              end
            else
              # * - single asterisk, match anything except /
              str << "[^/]*"
            end
          when '?'
            str << "[^/]"
          when '['
            # Character class
            str << '['
            i += 1
            # Handle negation [!...]
            if i < len && pattern[i] == '!'
              str << '^'
              i += 1
            end
            # Handle ] as first char
            if i < len && pattern[i] == ']'
              str << "\\]"
              i += 1
            end
            while i < len && pattern[i] != ']'
              if pattern[i] == '\\'
                str << '\\'
                i += 1
                if i < len
                  str << pattern[i]
                  i += 1
                end
              else
                str << Regex.escape(pattern[i].to_s) if ".^$".includes?(pattern[i])
                str << pattern[i] unless ".^$".includes?(pattern[i])
                i += 1
              end
            end
            str << ']'
          when '.', '+', '^', '$', '{', '}', '(', ')', '|'
            str << '\\'
            str << c
          else
            str << c
          end

          i += 1
        end

        str << "$"
      end

      Regex.new(regex_str)
    end
  end
end
