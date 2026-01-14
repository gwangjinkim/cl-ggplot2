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

## Milestone 2: Renderer & SVG Skeleton (Completed: 2026-01-14)

### New Features
- **Renderer Protocol**: Defined a generic interface for drawing primitives (`r-rect`, `r-line`, `r-circle`, etc.).
- **SVG Backend**: Implemented a deterministic SVG renderer with stable float formatting.
- **Render API**: Added `render` and `save` functions to produce plot output.
- **Plot Skeleton**: Implemented initial panel and axes drawing for the SVG output.

### Verification Results
- 2 new tests in `test/render-svg-tests.lisp` verifying SVG primitive generation and the plot skeleton.
- `make test` passes.

### Touched Files
- `cl-ggplot2.asd`
- `src/renderer.lisp`
- `src/render-api.lisp`
- `test/render-svg-tests.lisp`

## Milestone 3: Scales (Continuous x/y) (Completed: 2026-01-14)

### New Features
- **Scale Protocol**: Defined `scale-train`, `scale-map`, and `scale-breaks` for learning and mapping data domains.
- **Continuous Scales**: Implemented `scale-continuous` for numeric data.
- **NA Handling**: Scales correctly propagate `*na*` during mapping.
- **Breaks Generator**: Added a default breaks generator for axis ticks.

### Verification Results
- 4 new tests in `test/scale-tests.lisp` covering training, mapping, NA handling, and breaks.
- `make test` passes.

### Touched Files
- `cl-ggplot2.asd`
- `src/package.lisp`
- `src/scale.lisp`
- `test/scale-tests.lisp`

## Milestone 4: Geom Point & Stat Identity (Completed: 2026-01-14)

### New Features
- **Geom Point**: Added `geom_point` for scatter plots.
- **Stat Identity**: Added `stat_identity` for direct data mapping.
- **Build Pipeline**: Implemented the core orchestration logic that connects data, scales, and geoms.
- **Coordinate Inversion**: The build pipeline now correctly inverts Y-coordinates for SVG's top-down system.

### Verification Results
- 2 new tests in `test/build-tests.lisp` verifying scatter plot rendering with various parameters.
- `make test` passes.

### Touched Files
- `cl-ggplot2.asd`
- `src/package.lisp`
- `src/stat.lisp`
- `src/geom.lisp`
- `src/build.lisp`
- `test/build-tests.lisp`
