# Changelog

All notable changes to this project are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/). See AGENTS.md
("Change Discipline") for how entries and commits are written.

## [Unreleased]

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
