# ignoreme

A .gitignore compatible pattern parser for Crystal.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     ignoreme:
       github: transfire/ignoreme
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
