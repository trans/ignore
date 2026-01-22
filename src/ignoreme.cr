require "./ignoreme/pattern"

module Ignoreme
  VERSION = "0.2.0"

  # A collection of gitignore patterns that can match paths
  class Matcher
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
      return self unless File.exists?(path)
      parse(File.read(path), base)
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

    # Returns the number of patterns
    def size : Int32
      @patterns.size
    end

    # Check if matcher has any patterns
    def empty? : Bool
      @patterns.empty?
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

  # Load all .gitignore files from a directory tree
  # Patterns from deeper directories take precedence (loaded after shallower ones)
  def self.root(root : String) : Matcher
    from_directory(root)
  end

  # :ditto:
  def self.from_directory(root : String) : Matcher
    matcher = Matcher.new
    root = root.chomp("/")

    # Collect all .gitignore files with their relative base paths
    gitignore_files = [] of Tuple(String, String) # {file_path, base_path}

    # Check root .gitignore
    root_gitignore = File.join(root, ".gitignore")
    if File.exists?(root_gitignore)
      gitignore_files << {root_gitignore, ""}
    end

    # Find .gitignore files in subdirectories
    # Use **/*/.gitignore since **/.gitignore doesn't match dotfiles in Crystal
    Dir.glob(File.join(root, "**/*/.gitignore")) do |file|
      dir = File.dirname(file)
      base = dir[(root.size + 1)..]
      gitignore_files << {file, base}
    end

    # Sort by depth (shallower first) so deeper patterns come later and take precedence
    gitignore_files.sort_by! { |_, base| base.count("/") }

    gitignore_files.each do |file, base|
      matcher.add_file(file, base)
    end

    matcher
  end
end
