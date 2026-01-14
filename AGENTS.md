# AGENTS.md — cl-ggplot2 (Single public package)

This file is the **source of truth** for agents/Codex. Follow it literally.

Project goal: a native Common Lisp “ggplot2-like” plotting system that builds plots from
**data + aes mappings + layers**, and renders **deterministic SVG** first (snapshot tests).
We depend on `cl-tibble` and `cl-vctrs-lite`. Both are in the parent folder.

**Composition operator:** use **`-+`** as the plot-layer chaining operator, similar in spirit to `->`.
Target API:

```lisp
(-+ (ggplot d (aes :x :x :y :y :color :g))
    (geom_point)
    (geom_line)
    (theme_ggplot2_approx)
    (labs :title "Demo"))
```

---

## 0) Golden rules for agents

For each milestone M0..MN:

1) Write/adjust **FiveAM tests first**. Confirm they fail for the right reason.  
2) Implement minimal code to pass tests.  
3) Run: `make test` (canonical).  
4) **Write a report about the new features into `PROGRESS.md`.**
5) **Update `README.md` with new features and examples.**
6) Summarize changes + list touched files.  
7) STOP. Do not start next milestone unless asked.

Constraints:
- No refactors across unrelated modules.
- No “let’s also add geom_boxplot” while implementing geom_point.
- Keep output deterministic (especially SVG).
- Prefer simple data structures; performance later.

---

## 1) Packaging decision: single package

This project uses **one** public package:

- `CL-GGPLOT2` (exported API)

No additional public packages. Internals may live in separate source files, but they all use:
`(in-package #:cl-ggplot2)`.

---

## 2) Repo layout (required)

```
cl-ggplot2/
  AGENTS.md
  SPEC.md
  README.md
  ROSWELL.md
  Makefile
  cl-ggplot2.asd
  scripts/
    test.ros
  src/
    package.lisp         ; defines CL-GGPLOT2, exports API
    core.lisp            ; plot/mapping/layer classes + apply-to-plot
    operator.lisp        ; -+ macro and helpers
    aes.lisp             ; aes constructor and mapping utilities
    validate.lisp        ; validation helpers (columns exist, required aes)
    build.lisp           ; build pipeline skeleton

    stat.lisp            ; stat protocol + built-in stats (identity/count/bin)
    scale.lisp           ; scale protocol + built-in scales (cont/discrete, palettes, breaks)
    coord.lisp           ; coord protocol + cartesian
    theme.lisp           ; theme objects + theme_minimal + theme_ggplot2_approx
    labs.lisp            ; labs modifier
    geom.lisp            ; geom protocol + built-in geoms (point/line/bar/hist helper)

    renderer.lisp        ; renderer protocol + SVG renderer
    render-api.lisp      ; render/save entrypoints
  test/
    package.lisp
    suite.lisp
    smoke-tests.lisp

    operator-tests.lisp
    aes-tests.lisp
    build-tests.lisp

    stat-tests.lisp
    scale-tests.lisp

    render-svg-tests.lisp
    fixtures/
      scatter.svg
      line.svg
      bar.svg
      hist.svg
```

Notes:
- This keeps a **single CL package** but still separates code by concern.
- Do not add more files unless a milestone explicitly requires it.

---

## 3) Systems and dependencies

ASDF systems:
- `cl-ggplot2`
- `cl-ggplot2/test` (secondary system)

Dependencies:
- `cl-ggplot2` depends on: `cl-tibble`, `cl-vctrs-lite`
- `cl-ggplot2/test` depends on: `cl-ggplot2`, `fiveam`

Testing:
- FiveAM unit tests
- SVG snapshot tests (normalize SVG text then compare exact string)

---

## 4) Canonical commands (Roswell)

### make test
`make test` must run and exit 0/1 deterministically:

- `scripts/test.ros` loads local `cl-ggplot2.asd`
- runs `(asdf:test-system :cl-ggplot2/test)`
- prints `OK` on success
- exits with code 0 success / 1 fail
- does not drop into the debugger

Use the known-good pattern:
`ros -Q run --load scripts/test.ros --quit`

ROSWELL.md contains the rules for ROSWELL.

---

## 5) Public API surface (v0.1)

All exported symbols are in `CL-GGPLOT2`.

### 5.1 Core
- `ggplot`           ; (ggplot data &optional mapping) -> plot
- `aes`              ; (aes &key x y color fill size shape alpha group linetype) -> mapping
- `-+`               ; macro: compose plot with layers/modifiers

### 5.2 Geoms (layers)
- `geom_point`
- `geom_line`
- `geom_bar`
- `geom_histogram`   ; v0.1 helper (may desugar to geom_bar+stat_bin)

### 5.3 Stats
- `stat_identity`
- `stat_count`
- `stat_bin`

### 5.4 Scales (v0.1 minimal set)
- `scale_x_continuous`, `scale_y_continuous`
- `scale_x_discrete`, `scale_y_discrete`
- `scale_color_discrete`, `scale_color_continuous`

### 5.5 Themes + labels
- `theme_minimal`
- `theme_ggplot2_approx`
- `labs`

### 5.6 Output
- `render`           ; (render plot &key device width height dpi) -> string/bytes
- `save`             ; (save plot path &key device width height dpi)

### 5.7 Lispy DSL (Macro)
- `gg` or `with-plot` ; declarative macro for plot construction

---

## 6) The `-+` operator: exact semantics

### 6.1 `-+` is a macro
`-+` must:
- evaluate the first form to a plot object
- apply subsequent items left-to-right
- return the final plot

Items can be:
- a **layer** object (geom layer)
- a **modifier** object (scale, theme, labs, coord)
- (v0.1) no arbitrary function calls inside `-+` beyond these objects

### 6.2 How items are applied
Implement a generic function:

- `(defgeneric apply-to-plot (item plot))`

Default methods:
- item is `layer` -> append to plot layers
- item is `scale` -> add/replace scale by channel
- item is `theme` -> merge theme properties
- item is `labs` -> set labels

`-+` expands to repeated `(apply-to-plot item plot)` calls.

### 6.3 Tests for `-+`
- `(-+ (ggplot d) (geom_point) (geom_line))` results in a plot with 2 layers in order
- `-+` must be hygienic (no variable capture)
- errors if first argument is not a plot

---

## 7) Lispy DSL: Declarative composition

For a more "Lisp-native" feel, provide a macro that wraps the `-+` operator.

### 7.1 The `with-plot` / `gg` macro
Target syntax:
```lisp
(cl-ggplot2:gg (data mapping)
  (geom_point :color :cyl)
  (geom_smooth :method :lm)
  (theme_minimal)
  (labs :title "Car Performance"))
```

Semantics:
- The first argument is a list `(data &optional mapping)`.
- Subsequent forms are treated as layers or modifiers.
- Expands to a `let` binding for the plot and a series of `apply-to-plot` calls (or a single `-+` call).

---

## 7) Data + mapping rules (v0.1)

### 7.1 Data input
`ggplot` accepts:
- `cl-tibble:tibble`

Optional later: accept plist/alist by calling `cl-tibble:as-tibble`, but v0.1 should keep scope tight.

### 7.2 Mapping
`(aes :x :colname :y :other)` means:
- selectors are name-ish: keyword, symbol, or string
- normalize to string via helper `name->string`
- mapping stores selectors; evaluation happens during build step

### 7.3 Layer precedence
- plot mapping is default
- layer mapping overrides plot mapping for specified aesthetics
- constants passed to geom (e.g., `:color "red"`) override mapping for that layer

### 7.4 Missing values
`cl-vctrs-lite:*na*` is treated as missing.
v0.1 behavior:
- drop rows with NA in required aesthetics for that layer
- record drop count in build result (no logging required v0.1)

---

## 8) Internal architecture (pipeline)

### 8.1 Build pipeline (functions)
Implement `build-plot` that returns a “built plot” object containing:
- trained scales
- computed layer data (after stats)
- panel layout (single panel v0.1)
- renderer-ready instructions

Stages:
1) resolve data + mapping per layer
2) apply stat transform per layer -> transformed tibble
3) train scales on layer data across all layers
4) map aesthetics -> numeric positions, colors, sizes
5) compute layout (plot region, axes)
6) render via renderer backend

### 8.2 Determinism rules
- stable iteration order: never rely on hash-table iteration
- stable IDs: do not include random ids in SVG
- stable numeric formatting: use a consistent float printer
- stable whitespace normalization for snapshot tests

---

## 9) CLOS classes (required)

### 9.1 Core classes
- `plot`:
  - `data` (tibble)
  - `mapping` (mapping or NIL)
  - `layers` (list, in order)
  - `scales` (list or alist by channel)
  - `theme` (theme object)
  - `coord` (coord object)
  - `labels` (labs object)
  - `built` (optional cache; v0.1 may ignore caching)

- `mapping`:
  - slots for aes channels: x y color fill size shape alpha group linetype

- `layer`:
  - `geom` instance
  - `stat` instance
  - `position` (v0.1 identity only)
  - `data` (optional override)
  - `mapping` (optional override)
  - `params` plist for geom constants

### 9.2 Protocol objects
- `geom` base + geom subclasses
- `stat` base + stat subclasses
- `scale` base + scale subclasses
- `coord` base + cartesian
- `theme` object
- `labs` object

---

## 10) Protocols (generic functions)

### 10.1 Geom protocol
- `(defgeneric geom-required-aes (geom))` -> list of keywords
- `(defgeneric geom-default-stat (geom))` -> stat instance
- `(defgeneric geom-draw (geom built-layer ctx))` -> draws via renderer ctx

### 10.2 Stat protocol
- `(defgeneric stat-compute (stat data mapping params))` -> tibble

### 10.3 Scale protocol
- `(defgeneric scale-channel (scale))` -> keyword (:x, :y, :color, ...)
- `(defgeneric scale-train (scale values))`
- `(defgeneric scale-map (scale values))`
- `(defgeneric scale-breaks (scale))` -> ticks/labels

### 10.4 Renderer protocol
SVG renderer supports primitives:
- begin/end svg
- set stroke/fill/linewidth
- circle, line, polyline, rect, text
- begin/end group

---

## 11) Rendering: SVG v0.1

### 11.1 Output contract
`(render plot :device :svg :width 600 :height 400)` returns an SVG string.

### 11.2 SVG guidelines
- `<svg width="..." height="..." viewBox="0 0 W H">`
- top-left origin (SVG default)
- panel rect + margins for axes
- minimal axes:
  - axis line + ticks + tick labels
- legend may be omitted in v0.1 (tests must not require it)

### 11.3 Float formatting
Provide `(fmt-float x)` that:
- prints deterministically
- uses fixed precision then trims trailing zeros
Snapshot tests depend on this.

---

## 12) Testing strategy

### 12.1 Unit tests (FiveAM)
- `-+` composition
- mapping resolution (plot vs layer vs constants)
- stat_count + stat_bin correctness
- scale training and mapping

### 12.2 Snapshot tests
For each fixture:
- render plot to SVG
- normalize SVG (stable whitespace/newlines)
- compare exact string to fixture file

Fixtures (v0.1):
- scatter.svg (geom_point)
- line.svg (geom_line + grouping)
- bar.svg (geom_bar + stat_count)
- hist.svg (stat_bin)

---

## 13) Milestones (stop after M8 unless asked)

### M0 — Scaffold
Deliver:
- ASDF systems + packages
- scripts/test.ros + Makefile
- smoke test passes

### M1 — Core classes + `-+` operator + apply-to-plot
Implement:
- plot/mapping/layer classes
- `ggplot`, `aes`
- `-+` macro
- `apply-to-plot` generic + methods for `layer` (append only for now)

Tests:
- `-+` produces ordered layers
- `ggplot` stores data and mapping

### M2 — Renderer protocol + SVG skeleton
Implement:
- renderer protocol + SVG renderer
- `render` for empty plot skeleton:
  - svg header, panel rect, minimal axes placeholders

Tests:
- `render` returns string containing `<svg`
- stable header/footer content

### M3 — Scales: continuous x/y
Implement:
- continuous scale training: min/max ignoring NA
- mapping numeric values to panel coordinates
- simple breaks (e.g., 5 ticks) with stable labels

Tests:
- scale_map maps min->left, max->right (x), etc.
- breaks count and order stable

### M4 — geom_point + stat_identity
Implement:
- `geom_point` returns a layer (geom point + stat identity)
- resolve data + mapping -> x/y numeric positions
- draw circles for each point

Tests:
- point count equals rows (minus NA dropped)
- snapshot: scatter.svg

### M5 — geom_line + grouping
Implement:
- `geom_line` draws polylines per group
- grouping rules:
  - if :group mapped use it
  - else if :color discrete use it
  - else single group

Tests:
- two groups produce two polylines
- snapshot: line.svg

### M6 — geom_bar + stat_count
Implement:
- `stat_count`: for discrete x, count occurrences
- draw bars as rects
- discrete x positioning (even spacing)

Tests:
- counts correct
- snapshot: bar.svg

### M7 — stat_bin (histogram)
Implement:
- `stat_bin` for continuous x:
  - v0.1: fixed bins=30 default OR accept :bins param
  - output edges + counts
- draw bars as rects

Tests:
- total count equals non-NA rows
- snapshot: hist.svg

### M8 — Themes (minimal + ggplot2-ish approx)
Implement:
- `theme_minimal` and `theme_ggplot2_approx`
- apply theme to background, grid lines, axis styling
- update snapshots accordingly

Stop after M8 unless asked.

### M9 — Faceting: facet_wrap
Implement:
- basic `facet_wrap` layout
- split data by categorical variable(s)
- repeat geoms across panels

### M10 — Position Adjustments
Implement:
- `position_dodge` (bar side-by-side)
- `position_fill` (percentage stacks)
- update `geom_bar` to support them

### M11 — Coordinate Systems (basics)
Implement:
- `coord_flip` (swap x and y)
- `coord_fixed` (fixed aspect ratio)

### M12 — Advanced Stats
Implement:
- `stat_smooth` (LM/linear regression)
- `stat_summary` (mean/median points)

### M13 — Additional Aesthetics
Implement:
- `scale_size`, `scale_shape`, `scale_alpha`
- mapping data to these channels in `aes`

### M14 — Legends & Color Palettes
Implement:
- multi-legend layout (combining color, size, etc.)
- integration with `cl-colors` or similar for Viridis/ColorBrewer

### M15 — Annotations
Implement:
- `annotate` function for manual additions
- `geom_text` for label mapping

---

## 14) Coding conventions

- Keep modules small and single-purpose.
- Avoid macros except `-+` and small helpers.
- Use `cl-tibble` column access and `cl-vctrs-lite` NA semantics.
- Never rely on hash-table iteration order.
- Prefer vectors internally for deterministic output.
- Every exported function must have a short docstring.

---

## 15) Definition of done (v0.1)
- `make test` passes
- SVG snapshots pass consistently
- API supports: scatter, line, bar, histogram
- `-+` chaining works and is tested
- output is deterministic enough for snapshot tests
- **`PROGRESS.md` is updated with milestone results**
- **`README.md` reflects current features**
