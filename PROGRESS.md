# PROGRESS.md — cl-ggplot2

## Milestone 1: Core Classes & DSL (Completed: 2026-01-14)

### New Features
- **Object Model**: Implemented `plot`, `mapping`, and `layer` classes using CLOS.
- **Constructors**: Added `ggplot` and `aes` for initial plot specification.
- **Composition Operator**: Added the `-+` threading-like macro for chaining plot components.
- **Lispy DSL**: Added the `gg` (and `with-plot`) declarative macro for elegant plot construction.
- **Generic Protocol**: Implemented `apply-to-plot` for extensibility.

### Verification Results
- 5 new tests in `test/operator-tests.lisp` covering constructors and DSL macros.
- `make test` passes successfully.

### Touched Files
- `cl-ggplot2.asd`
- `src/package.lisp`
- `src/core.lisp`
- `src/aes.lisp`
- `src/apply.lisp`
- `src/operator.lisp`
- `test/operator-tests.lisp`
