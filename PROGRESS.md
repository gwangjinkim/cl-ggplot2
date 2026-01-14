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

## Milestone 6: Scales (Discrete/Categorical) (Completed: 2026-01-14)

### New Features
- **Discrete Scales**: Added `scale-discrete` for non-numeric data (strings, symbols).
- **Domain Learning**: Automatically extracts unique values in order of appearance.
- **Equidistant Mapping**: Maps discrete categories to evenly spaced points across the output range.

### Verification Results
- 3 new tests in `test/scale-discrete-tests.lisp` covering training, linear mapping, and breaks.
- `make test` passes without warnings.

### Touched Files
- `cl-ggplot2.asd`
- `src/scale.lisp`
- `test/scale-discrete-tests.lisp`

## Milestone 7: Geometric Primitives (Bar/Rect) (Completed: 2026-01-14)

### New Features
- **Stat Count**: New `stat-count` for aggregating non-numeric data into frequencies.
- **Geom Bar**: Added `geom_bar` for frequency bars and `geom_col` for identity bars.
- **Geom Tile**: Added `geom_tile` for rectangular areas/heatmaps.
- **Build Pipeline Upgrades**: The pipeline now supports multi-stage transformations (Stat -> Scale -> Map).

### Verification Results
- 3 new tests in `test/geom-bar-tests.lisp` covering stat aggregation and area drawing.
- `make test` passes.

### Touched Files
- `cl-ggplot2.asd`
- `src/package.lisp`
- `src/stat.lisp`
- `src/geom.lisp`
- `src/build.lisp`
- `test/geom-bar-tests.lisp`

## Milestone 8: Labels & Themes (Minimal) (Completed: 2026-01-14)

### New Features
- **Labs**: Added `labs` function for setting title, subtitle, and axis labels.
- **Themes**: Added `theme_minimal` for a cleaner plot aesthetic.
- **Gridlines**: Added basic gridline rendering in the plot skeleton.
- **Text Rendering**: SVG renderer now supports text anchors, angles, and alignment.

### Verification Results
- 4 new tests in `test/theme-tests.lisp` covering label updates and SVG content scanning.
- `make test` passes.

### Touched Files
- `cl-ggplot2.asd`
- `src/package.lisp`
- `src/core.lisp`
- `src/build.lisp`
- `src/theme.lisp`
- `test/theme-tests.lisp`

## Milestone 9: Color & Fill Scales (Discrete) (Completed: 2026-01-14)

### New Features
- **Discrete Color/Fill Scales**: Added `scale_color_discrete` and `scale_fill_discrete` with a default categorical palette.
- **Aesthetic Overrides**: Constants passed to `geom_*` functions (e.g., `:color "blue"`) now correctly override aesthetic mappings.
- **Stat Mapping Persistence**: Stats no longer drop unrelated aesthetic mappings (e.g., `:fill` is preserved when using `stat_count`).
- **Vectorized Geoms**: `geom-draw` now correctly handles both mapped vectors and constant scalars for color, fill, size, and alpha.

### Verification Results
- 3 new tests in `test/scale-color-tests.lisp` covering discrete mapping and constant overrides.
- All existing tests pass.

### Touched Files
- `cl-ggplot2.asd`
- `src/package.lisp`
- `src/scale.lisp`
- `src/stat.lisp`
- `src/build.lisp`
- `src/geom.lisp`
- `test/geom-stat-adv-tests.lisp`

## Milestone 10: Additional Geoms (Histogram, Boxplot) (Completed: 2026-01-14)

### New Features
- **Histograms**: `geom_histogram` with `stat_bin`. Supports `:bins` parameter.
- **Boxplots**: `geom_boxplot` with `stat_boxplot`. Computes and renders median, hinges (25/75th percentiles), and whiskers.
- **Secondary Aesthetic Mapping**: `build-plot` now correctly maps and trains scales for `xmin`, `xmax`, `ymin`, `ymax`, `middle`, `lower`, and `upper`.
- **Aesthetic Slot Robustness**: Improved `slot-value` handling for aesthetic keywords in the build pipeline.

### Verification Results
- 3 new tests in `test/geom-stat-adv-tests.lisp` for binning, quantiles, and rendering.
- All 15+ tests pass (`make test`).

### Touched Files
- `cl-ggplot2.asd`
- `src/package.lisp`
- `src/core.lisp`
- `src/stat.lisp`
- `src/build.lisp`
- `src/geom.lisp`
- `test/geom-stat-adv-tests.lisp`

## Milestone 5: Geom Line & Path (Completed: 2026-01-14)

### New Features
- **Geom Path**: Added `geom_path` for drawing connected sequences of points.
- **Geom Line**: Added `geom_line` which automatically sorts data by the X aesthetic before drawing.
- **NA Handling in Paths**: Paths and lines correctly break at points containing `*na*`.

### Verification Results
- 2 new tests in `test/geom-line-tests.lisp` verifying path order and line sorting.
- `make test` passes.

### Touched Files
- `cl-ggplot2.asd`
- `src/package.lisp`
- `src/geom.lisp`
- `src/build.lisp`
- `test/geom-line-tests.lisp`

## Milestone 12: Faceting with `facet_wrap` (Completed: 2026-01-14)

### New Features
- **Faceting Infrastructure**: Added `facet_wrap` and the `facet-wrap` class.
- **Multi-Panel Build Pipeline**: `build-plot` now splits data by facet variables and calculates coordinates for multiple panels.
- **Global Scale Training**: Scales are now trained globally across all panels to ensure visual consistency.
- **Panel Skeletons**: Each facet panel is drawn with its own background, gridlines, and "strip" (facet label).
- **Coordinate Mapping**: Data is mapped to panel-specific coordinates within the global SVG canvas.

### Verification Results
- 2 new tests in `test/facet-tests.lisp` verifying facet resolution and SVG rendering.
- Updated 15+ existing tests to account for the new panel-based structure.
- All tests pass (`make test`).

### Touched Files
- `cl-ggplot2.asd`
- `src/package.lisp`
- `src/core.lisp`
- `src/facet.lisp`
- `src/build.lisp`
- `src/geom.lisp`
- `test/facet-tests.lisp`
