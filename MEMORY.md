# Project Memory

Notes for future development sessions.

## Project Overview

**ignore** is a Crystal library for gitignore-compatible pattern matching and filtered directory operations.

- **Shard name:** `ignore`
- **GitHub:** `trans/ignore`
- **Namespace:** `Ignore::`
- **Current version:** 0.4.1
- **Website:** https://trans.github.io/ignore/
- **API Docs:** https://trans.github.io/ignore/api/

## File Structure

```
src/
├── ignore.cr          # Main module, Matcher class, module-level API
└── ignore/
    ├── pattern.cr     # Pattern class (gitignore → regex conversion)
    ├── dir.cr         # Dir class (filtered directory operations)
    ├── file.cr        # File class (read/modify/save ignore files)
    └── core_ext.cr    # Optional Dir monkey patch
```

## Key Classes

- `Ignore::Pattern` — Single pattern, compiles to regex
- `Ignore::Matcher` — Collection of patterns, handles precedence
- `Ignore::Dir` — Filtered directory operations (glob, children, etc.)
- `Ignore::File` — Read/modify/save ignore files, preserves comments

## Conventions

- All modifier methods return `self` for chaining
- Matcher, Dir, and File all include `Enumerable(String)`
- Use `::File` and `::Dir` to reference stdlib when inside the `Ignore` module
- Tests use `around_each` with temp directories for isolation
- Commit messages serve as changelog (keep them detailed)

## Build Tasks

Use `just` to run common tasks:

- `just test` — run specs (default)
- `just docs` — generate API docs
- `just fmt` — format code
- `just check` — format check + tests
- `just release <version>` — check, tag, push

## Docs Structure

```
docs/
├── index.html   # Project website (GitHub Pages)
└── api/         # Generated API docs (crystal docs)
```

Regenerate API docs with `just docs` before releases.

## History

- v0.3.0: Original release as `ignoreme` with `Ignoreme::` namespace
- v0.4.0: Renamed to `ignore` / `Ignore::`, added File class, Enumerable support, inverse filtering, reload, etc.
- v0.4.1: Added project website, Justfile, and API documentation

## Future Ideas

### Global Gitignore Support

Git supports a global ignore file at `~/.config/git/ignore` (or configured via `core.excludesFile`). Could add:

```crystal
# Load global gitignore
matcher = Ignore.global

# Combine global + project ignores
matcher = Ignore.global.merge(Ignore.root("/path/to/project"))
```

Implementation notes:
- Check `git config --global core.excludesFile` first
- Fall back to `~/.config/git/ignore`
- Consider XDG_CONFIG_HOME

### Other Potential Enhancements

- `Ignore::File#comment(text)` — Add a comment line
- `Ignore::File#section(name) { }` — Group patterns under a comment header
- Performance: lazy Pattern compilation for large ignore files
- `Ignore.from_string` alias for `Ignore.parse`
