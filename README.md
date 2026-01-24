# ignoreme

A .gitignore compatible pattern parser for Crystal.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     ignoreme:
       github: trans/ignoreme
   ```

2. Run `shards install`

## Usage

```crystal
require "ignoreme"

# Parse gitignore content
matcher = Ignoreme.parse(<<-GITIGNORE
  build/
  *.o
  *.log
  !important.log
GITIGNORE
)

matcher.ignores?("build/")       # => true (directory)
matcher.ignores?("main.o")       # => true
matcher.ignores?("debug.log")    # => true
matcher.ignores?("important.log") # => false (negated)

# Quick one-liner
Ignoreme.ignores?("foo.log", "*.log")  # => true
```

### Directory Matching

Use a trailing slash to check directories:

```crystal
matcher = Ignoreme.parse("build/")
matcher.ignores?("build/")  # => true (directory)
matcher.ignores?("build")   # => false (file)
```

### Building Patterns Incrementally

```crystal
matcher = Ignoreme::Matcher.new
matcher.add("*.o")
matcher.add("*.log")
matcher.add("!important.log")
matcher.ignores?("test.o")  # => true
```

### Loading from a Directory Tree

Load all `.gitignore` files from a project, with patterns scoped to their directories:

```crystal
matcher = Ignoreme.root("/path/to/project")
matcher.ignores?("src/debug.log")
```

This loads `.gitignore` files from the root and all subdirectories. Patterns from deeper directories take precedence, so a `!debug.log` in `src/.gitignore` will override `*.log` in the root `.gitignore`.

You can also load other ignore file formats:

```crystal
# Load .dockerignore files
matcher = Ignoreme.root("/path/to/project", ".dockerignore")

# Load .npmignore files
matcher = Ignoreme.root("/path/to/project", ".npmignore")
```

### Loading Individual Files

```crystal
matcher = Ignoreme::Matcher.new
matcher.add_file(".gitignore")
matcher.add_file("src/.gitignore", base: "src/")
```

### Filtered Directory Operations

Use `Ignoreme::Dir` for filtered directory listings and glob results:

```crystal
dir = Ignoreme::Dir.new("/path/to/project", "*.log", "build/")

dir.glob("**/*.cr")           # filtered glob
dir.children                   # filtered directory children
dir.entries                    # filtered entries (includes . and ..)
dir.each_child { |entry| ... } # filtered iteration

# Load patterns from .gitignore files automatically
dir = Ignoreme::Dir.new("/path/to/project", root: ".gitignore")

# Load from a single ignore file
dir = Ignoreme::Dir.new("/path/to/project", file: ".gitignore")
```

Directory patterns like `build/` will filter out the directory and all its contents.

#### Dir Monkey Patch (Optional)

For convenience, you can optionally load a monkey patch that adds `ignore` methods to `Dir`:

```crystal
require "ignoreme/ext/dir"

# Class method (uses current directory)
Dir.ignore("*.log", "build/").glob("**/*")
Dir.ignore(root: ".gitignore").glob("**/*")

# Instance method
Dir.new("/path/to/project").ignore("*.log").glob("**/*")
Dir.new("/path/to/project").ignore(root: ".gitignore").children
```

## Supported Patterns

| Pattern | Description |
|---------|-------------|
| `*.txt` | Wildcard, matches any `.txt` file |
| `?` | Single character wildcard |
| `[abc]` | Character class |
| `[a-z]` | Character range |
| `[!abc]` | Negated character class |
| `build/` | Directory only (trailing slash) |
| `/root` | Anchored to root (leading slash) |
| `foo/bar` | Anchored (contains slash) |
| `!pattern` | Negation (un-ignore) |
| `**/foo` | Match in all directories |
| `foo/**` | Match everything inside |
| `a/**/b` | Zero or more directories between |
| `\#` `\!` | Escaped special characters |

## License

MIT
