module Ignore
  # A directory wrapper that filters results using gitignore patterns
  class Dir
    @matcher : Matcher
    @path : String

    # Initialize with path and pattern strings
    def initialize(@path : String, *patterns : String)
      @matcher = Matcher.new
      patterns.each { |p| @matcher.add(p) }
    end

    # Initialize with path and enumerable of patterns
    def initialize(@path : String, patterns : Enumerable(String))
      @matcher = Matcher.new
      patterns.each { |p| @matcher.add(p) }
    end

    # Initialize with path and existing matcher
    def initialize(@path : String, @matcher : Matcher)
    end

    # Initialize with path, loading patterns from ignore files in tree
    def initialize(@path : String, *, root : String)
      @matcher = Ignore.from_directory(@path, root)
    end

    # Initialize with path, loading patterns from a single file
    def initialize(@path : String, *, file : String, base : String = "")
      @matcher = Matcher.new
      @matcher.add_file(file, base)
    end

    # The base path
    getter path : String

    # Add additional patterns
    def add(pattern : String) : self
      @matcher.add(pattern)
      self
    end

    # Glob with filtering, returns array
    def glob(pattern : String) : Array(String)
      results = [] of String
      glob(pattern) { |path| results << path }
      results
    end

    # Glob with filtering, yields each match
    def glob(pattern : String, &block : String ->) : Nil
      full_pattern = ::File.join(@path, pattern)
      ::Dir.glob(full_pattern) do |path|
        yield path unless ignores_path?(path)
      end
    end

    # Returns children of base directory, filtered
    def children : Array(String)
      ::Dir.children(@path).reject { |entry| ignores_entry?(entry) }
    end

    # Returns entries of base directory (includes . and ..), filtered
    def entries : Array(String)
      ::Dir.entries(@path).reject do |entry|
        next false if entry == "." || entry == ".."
        ignores_entry?(entry)
      end
    end

    # Iterate over children, filtered
    def each_child(& : String ->) : Nil
      ::Dir.each_child(@path) do |entry|
        yield entry unless ignores_entry?(entry)
      end
    end

    # Check if a path should be ignored
    def ignores?(path : String) : Bool
      @matcher.ignores?(path)
    end

    private def ignores_path?(path : String) : Bool
      # Get path relative to base for matching
      relative = path.starts_with?(@path) ? path[@path.size..].lstrip('/') : path
      check_path = ::File.directory?(path) ? relative + "/" : relative
      return true if @matcher.ignores?(check_path)

      # Also check if any parent directory is ignored
      parts = relative.split('/')
      (1...parts.size).each do |i|
        parent = parts[0...i].join('/') + "/"
        return true if @matcher.ignores?(parent)
      end

      false
    end

    private def ignores_entry?(entry : String) : Bool
      full_path = ::File.join(@path, entry)
      check_path = ::File.directory?(full_path) ? entry + "/" : entry
      @matcher.ignores?(check_path)
    end
  end
end
