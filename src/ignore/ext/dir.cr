require "../dir"

# Monkey patch Dir to add ignore methods
class Dir
  # Instance method: returns an Ignore::Dir based on this Dir's path
  def ignore(*patterns : String) : Ignore::Dir
    Ignore::Dir.new(self.path, *patterns)
  end

  # Instance method: load patterns from ignore files in this directory tree
  def ignore(*, root : String) : Ignore::Dir
    Ignore::Dir.new(self.path, root: root)
  end

  # Instance method: load patterns from a single file
  def ignore(*, file : String, base : String = "") : Ignore::Dir
    Ignore::Dir.new(self.path, file: file, base: base)
  end

  # Class method: patterns with current directory
  def self.ignore(*patterns : String) : Ignore::Dir
    Ignore::Dir.new(Dir.current, *patterns)
  end

  # Class method: load from ignore files in current directory tree
  def self.ignore(*, root : String) : Ignore::Dir
    Ignore::Dir.new(Dir.current, root: root)
  end

  # Class method: load from single file, current directory
  def self.ignore(*, file : String, base : String = "") : Ignore::Dir
    Ignore::Dir.new(Dir.current, file: file, base: base)
  end
end
