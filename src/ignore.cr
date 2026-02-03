require "./ignore/pattern"
require "./ignore/dir"
require "./ignore/file"

module Ignore
  VERSION = "0.3.0"

  # A collection of gitignore patterns that can match paths
  class Matcher
    include Enumerable(String)

    @patterns : Array(Pattern)

    def initialize
      @patterns = [] of Pattern
    end

    # Add a single pattern string
    def add(pattern : String, base : String = "") : self
      stripped = pattern.strip
      return self if stripped.empty? || stripped.starts_with?("#")
      @patterns << Pattern.new(stripped, base)
      self
    end

    # Parse gitignore content (multiple lines)
    def parse(content : String, base : String = "") : self
      content.each_line do |line|
        add(line, base)
      end
      self
    end

    # Load patterns from a .gitignore file
    def add_file(path : String, base : String = "") : self
      return self unless ::File.exists?(path)
      parse(::File.read(path), base)
    end

    # Check if a path should be ignored
    # Use trailing / for directories: ignores?("build/")
    def ignores?(path : String) : Bool
      result = false

      @patterns.each do |pattern|
        if pattern.matches?(path)
          result = !pattern.negated?
        end
      end

      result
    end

    # Returns the pattern strings
    def patterns : Array(String)
      @patterns.map(&.pattern)
    end

    # Iterate over pattern strings
    def each(& : String ->) : Nil
      @patterns.each { |p| yield p.pattern }
    end

    # Returns the number of patterns
    def size : Int32
      @patterns.size
    end

    # Check if matcher has any patterns
    def empty? : Bool
      @patterns.empty?
    end

    # Remove all patterns
    def clear : self
      @patterns.clear
      self
    end
  end

  # Parse gitignore content and return a Matcher
  def self.parse(content : String) : Matcher
    Matcher.new.parse(content)
  end

  # Quick check if a path matches patterns
  def self.ignores?(path : String, patterns : String) : Bool
    parse(patterns).ignores?(path)
  end

  # Load all ignore files from a directory tree
  # Patterns from deeper directories take precedence (loaded after shallower ones)
  def self.root(root : String, ignore_file : String = ".gitignore") : Matcher
    from_directory(root, ignore_file)
  end

  # :ditto:
  def self.from_directory(root : String, ignore_file : String = ".gitignore") : Matcher
    matcher = Matcher.new
    root = root.chomp("/")

    # Collect all ignore files with their relative base paths
    found_files = [] of Tuple(String, String) # {file_path, base_path}

    ::Dir.glob(::File.join(root, "**/#{ignore_file}"), match: :dot_files) do |file|
      dir = ::File.dirname(file)
      base = dir == root ? "" : dir[(root.size + 1)..]
      found_files << {file, base}
    end

    # Sort by depth (shallower first) so deeper patterns come later and take precedence
    found_files.sort_by! { |_, base| base.count("/") }

    found_files.each do |file, base|
      matcher.add_file(file, base)
    end

    matcher
  end
end
