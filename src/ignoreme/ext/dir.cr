require "../dir"

# Monkey patch Dir to add ignore methods
class Dir
  # Instance method: returns an Ignoreme::Dir based on this Dir's path
  def ignore(*patterns : String) : Ignoreme::Dir
    Ignoreme::Dir.new(self.path, *patterns)
  end

  # Instance method: load patterns from ignore files in this directory tree
  def ignore(*, root : String) : Ignoreme::Dir
    Ignoreme::Dir.new(self.path, root: root)
  end

  # Instance method: load patterns from a single file
  def ignore(*, file : String, base : String = "") : Ignoreme::Dir
    Ignoreme::Dir.new(self.path, file: file, base: base)
  end

  # Class method: patterns with current directory
  def self.ignore(*patterns : String) : Ignoreme::Dir
    Ignoreme::Dir.new(Dir.current, *patterns)
  end

  # Class method: load from ignore files in current directory tree
  def self.ignore(*, root : String) : Ignoreme::Dir
    Ignoreme::Dir.new(Dir.current, root: root)
  end

  # Class method: load from single file, current directory
  def self.ignore(*, file : String, base : String = "") : Ignoreme::Dir
    Ignoreme::Dir.new(Dir.current, file: file, base: base)
  end
end
