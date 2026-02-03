module Ignore
  # Represents an ignore file (like .gitignore) that can be read, modified, and saved
  class File
    @path : String
    @lines : Array(String)
    @matcher : Matcher?

    # Initialize from a file path
    # By default, creates empty if file doesn't exist
    # Set create: false to raise if file doesn't exist
    def initialize(@path : String, create : Bool = true)
      if ::File.exists?(@path)
        @lines = ::File.read_lines(@path)
      elsif create
        @lines = [] of String
      else
        raise ::File::NotFoundError.new("File not found: #{@path}", file: @path)
      end
      @matcher = nil
    end

    # The file path
    getter path : String

    # All lines including comments and blank lines
    def lines : Array(String)
      @lines.dup
    end

    # Only pattern lines (excludes comments and blank lines)
    def patterns : Array(String)
      @lines.select { |line| pattern?(line) }
    end

    # Number of patterns (excludes comments and blank lines)
    def size : Int32
      @lines.count { |line| pattern?(line) }
    end

    # Check if there are no patterns
    def empty? : Bool
      !@lines.any? { |line| pattern?(line) }
    end

    # Add a pattern (appends to end)
    def add(pattern : String) : self
      @lines << pattern
      @matcher = nil
      self
    end

    # Remove a pattern (first occurrence)
    def remove(pattern : String) : self
      if idx = @lines.index(pattern)
        @lines.delete_at(idx)
        @matcher = nil
      end
      self
    end

    # Check if a pattern exists
    def includes?(pattern : String) : Bool
      @lines.includes?(pattern)
    end

    # Remove all lines (patterns, comments, and blanks)
    def clear : self
      @lines.clear
      @matcher = nil
      self
    end

    # Check if a path should be ignored
    def ignores?(path : String) : Bool
      matcher.ignores?(path)
    end

    # Save to file (original path or specified path)
    def save(path : String = @path) : self
      ::File.write(path, @lines.join("\n") + (@lines.empty? ? "" : "\n"))
      self
    end

    # Check if a line is a pattern (not a comment or blank)
    private def pattern?(line : String) : Bool
      stripped = line.strip
      !stripped.empty? && !stripped.starts_with?("#")
    end

    # Build or return cached matcher
    private def matcher : Matcher
      @matcher ||= begin
        m = Matcher.new
        @lines.each { |line| m.add(line) }
        m
      end
    end
  end
end
