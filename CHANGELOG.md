# Changelog

All notable changes to this project are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/). See AGENTS.md
("Change Discipline") for how entries and commits are written.

## [Unreleased]

### Added
- `:version "0.1.0"` in `cl-ggplot2.asd`; it was the only package in the
  stack without a version, so `(asdf:component-version ...)` and
  `tidyverse:tidyverse-packages` reported NIL for it (topic: versioning).

### Fixed
- **`(gg (df (aes ...)) ...)` broke whenever the data variable was named
  `data`.** Commit ca5706c ("fix gg unbound data") made any spec starting
  with the symbol `DATA` mean "the second element is the data", so
  `(gg (data (aes :x :x :y :y)) ...)` used the *aes object* as data and
  rendering failed with `slot X is missing from the object NIL`. This
  broke 17 tests. `gg` now checks for a literal `(aes ...)` second
  element first, so both `(gg (data EXPR) ...)` and
  `(gg (EXPR (aes ...)) ...)` work. The accepted spec shapes are
  documented in the docstring (topic: gg macro).

### Changed
- Stopped tracking `build/` (48 files, 1.0M): the ASDF/Roswell compile
  cache that `make test` writes via `XDG_CACHE_HOME=$(PWD)/build`. It held
  compiled fasls, including Quicklisp internals and absolute local paths.
  `build/` is now in `.gitignore`; local files are untouched. Old copies
  remain in history (topic: repo hygiene).

### Tests
- `test-gg-macro-data-keyword` checked `(typep x 'cl-tibble:tibble)`;
  `tibble` is the constructor function, the class is `cl-tibble:tbl`.
- `smoke-test`: bare `(is t)` replaced by `(pass)` (current FiveAM rejects
  it). Suite: 103/103 pass (was 59/78 before the gg fix).
