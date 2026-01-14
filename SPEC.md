# SPEC.md — cl-ggplot2 (Common Lisp “Grammar of Graphics” plotting)

## 1. Purpose

`cl-ggplot2` is a Common Lisp plotting library inspired by R’s **ggplot2**. It provides a **Grammar of Graphics** API:
- construct plots from **data + aesthetic mappings + layers**
- add **geoms**, **stats**, **scales**, **coordinates**, **facets**, and **themes**
- render to **SVG/PNG/PDF** via a backend renderer

This is not “a wrapper around R.” It is a native CL library that aims to feel ggplot-ish and composable.

---

## 2. Can it generate plots that look *exactly* like ggplot2?

**Byte-identical / pixel-identical replication of ggplot2 output is not a realistic goal** across machines and environments, even in R, because the final appearance depends on:
- font availability + font rendering engine
- anti-aliasing differences
- text layout (line breaking / kerning)
- graphics device implementation details

What *is* realistic:
- **Very close visual parity** for common plot types (lines, points, bars, histograms) using a similar default theme.
- A **“theme_ggplot2_approx”** that matches ggplot2’s defaults closely.
- Deterministic rendering to SVG (more stable than raster) and snapshot tests.

So the goal should be:
- **compatible mental model + API style + comparable aesthetics**
- plus an “approx ggplot2 defaults” theme
- not strict identity.

---

## 3. Scope

### v0.1 (MVP)
- data input: `cl-tibble:tibble` and simple alists/plists
- mappings via `aes(...)`
- layers: `geom_point`, `geom_line`, `geom_bar`
- stats: identity, count, bin (basic histogram)
- scales: continuous x/y, discrete x/y, color discrete/continuous
- coords: cartesian only
- theme: minimal default + “ggplot2-ish” theme
- facets: none (v0.1)
- output: **SVG** first; PNG/PDF optional later (via Cairo backend)

### v0.2+
- facets (`facet_wrap`, `facet_grid`)
- more geoms (boxplot, area, smooth, text)
- more stats (summary, smoothing, bin2d)
- guides/legends improvements (multi-aesthetic legends)
- coordinate transforms (flip, fixed, polar basics)
- interactive output (optional; via Vega-Lite export)
- high-level declarative DSL (`gg` macro)

---

## 4. Non-goals (at least initially)
- full ggplot2 feature parity
- NSE/tidy-eval like R (CL macros cover most needs; keep it CL-native)
- GPU rendering or ultra-performance
- interactive JS plots unless via explicit export path

---

## 5. Public API (proposed)

### 5.1 Core constructors
- `(ggplot data &key mapping theme coord facets)` → returns a plot object
- `(aes &key x y color fill size shape alpha group linetype)` → mapping object
- `(+ plot layer-or-modifier)` or `(add plot ...)` for layering (choose one canonical)
  - Recommended CL idiom: `(add plot (geom_point ...) (scale_x_continuous ...) ...)`

### 5.2 Layers
Each layer has:
- geom (required)
- stat (default depends on geom)
- position adjustment (optional)
- mapping (optional override)
- data (optional override)
- params (geom-specific options)

Examples:
- `(geom_point &key mapping data size alpha color shape)`
- `(geom_line &key mapping data linewidth linetype alpha)`
- `(geom_bar &key mapping data stat position width)`

### 5.3 Scales
- `(scale_x_continuous &key name limits breaks labels trans)`
- `(scale_y_continuous ...)`
- `(scale_x_discrete &key name limits)`
- `(scale_color_discrete &key palette name)`
- `(scale_color_continuous &key palette name limits)`
- similarly for `fill`, `size`, `shape`

### 5.4 Themes
- `(theme &key text axis panel grid legend plot background ...)`
- `(theme_minimal)`
- `(theme_ggplot2_approx)` (ship a default that’s “close enough”)

### 5.5 Labels
- `(labs &key title subtitle caption x y color fill)`

### 5.6 Rendering / output
- `(render plot &key (device :svg) width height dpi)` → returns bytes/string
- `(save plot path &key device width height dpi)`

---

## 6. Data model

### 6.1 Data representation
Primary: `cl-tibble:tibble`

Secondary conversion via `(as-dataframe x)`:
- plist/alist → tibble
- hash-table → tibble (stable order)

### 6.2 Column access
Use `cl-tibble:tb-col` to fetch columns.
Use `cl-vctrs-lite` for:
- `*na*` handling
- `col-length`, `col-ref`, `col-map`, `col-subseq`
- `col-type`, coercion rules where needed

---

## 7. Internal architecture

### 7.1 Objects (CLOS)
- `plot` class:
  - `data`, `mapping`, `layers`, `scales`, `theme`, `coord`, `facets`, `labels`
- `mapping` class (aes)
- `layer` class:
  - `geom`, `stat`, `position`, `data`, `mapping`, `params`
- `geom` protocol (generic functions)
- `stat` protocol
- `scale` protocol
- `coord` protocol
- `theme` object

### 7.2 Pipeline stages
1) **Build**: combine plot + layers + mappings + data
2) **Compute**: apply stat transforms per layer (binning, counting)
3) **Train scales**: infer domain/range, breaks, palettes
4) **Map aesthetics**: produce concrete values (colors, sizes, positions)
5) **Layout**: panel area, axes, legend, margins
6) **Render**: backend draws primitives

---

## 8. Protocols (generic functions)

### 8.1 Geom protocol
- `(geom-required-aes geom)` → list of required aes keys
- `(geom-default-stat geom)` → stat instance
- `(geom-default-position geom)` → position adjustment
- `(geom-draw geom layer-data ctx)` → draw primitives into renderer context

### 8.2 Stat protocol
- `(stat-compute stat layer-data mapping)` → returns transformed data (tibble)

### 8.3 Scale protocol
- `(scale-train scale values)` → update domain info
- `(scale-map scale values)` → mapped aesthetics (numbers/colors/strings)
- `(scale-breaks scale)` → axis tick positions/labels

### 8.4 Coord protocol
- `(coord-transform coord x y)` → transformed coordinates
- v0.1 only cartesian identity

### 8.5 Renderer protocol (backend)
- `move-to`, `line-to`, `circle`, `rect`, `text`, `set-stroke`, `set-fill`, etc.
- Implement `renderer-svg` first (string builder for SVG)
- Later: `renderer-cairo` for PNG/PDF

---

## 9. Aesthetics semantics

### 9.1 Aesthetic mapping vs constants
- mapping: `(aes :x 'sepal_length :y 'sepal_width :color 'species)`
- constant param: `(geom_point :color "red" :size 2.0)`

Rules:
- layer params override plot mapping
- layer mapping overrides plot mapping
- missing values (`cl-vctrs-lite:*na*`) are dropped with a warning count by default
  - configurable: `na.rm` behavior

### 9.2 Grouping
- `:group` aesthetic controls line grouping etc.
- if discrete color/fill is mapped and group is missing, infer group from it (like ggplot2)

---

## 10. Theme and style defaults

### 10.1 Provide deterministic defaults
- default font family: allow user override, but pick a sane cross-platform default (e.g., “sans-serif” in SVG)
- default line widths, point sizes, grid line alpha
- define `theme_ggplot2_approx` that visually resembles ggplot2 theme_gray

### 10.2 Legend defaults
- show legend if an aesthetic is mapped to data (color/fill/shape)
- hide legend if only constants are used

---

## 11. Error handling

- User-facing errors must be clear and mention the offending aes/column:
  - unknown column name in mapping
  - required aes missing for geom
  - non-numeric values for continuous scale
  - length mismatches in layer data

Use CL conditions with readable messages.

---

## 12. Testing strategy

### 12.1 Unit tests (FiveAM)
- mapping resolution rules (plot mapping vs layer mapping)
- stat outputs (count/bin)
- scale training and mapping
- dropping NA behavior
- layout calculations (axis ranges, breaks count)

### 12.2 Snapshot tests (SVG)
For deterministic testing:
- render simple known plots to SVG
- compare normalized SVG strings (strip timestamps/ids if any)
- keep fixtures under `test/fixtures/*.svg`

Golden tests:
- scatter: `geom_point`
- line: `geom_line` with grouping
- bar: `geom_bar` with stat=count
- histogram: `geom_bar` with stat=bin

### 12.3 “Approx ggplot2” tests (optional)
Not pixel-perfect; instead verify:
- presence of expected elements (axes, labels, legend)
- approximate style attributes (grid color, background)

---

## 13. Repo layout (recommended)

```
cl-ggplot2/
cl-ggplot2.asd
SPEC.md
AGENTS.md
ROSWELL.md
Makefile
scripts/test.ros
src/
package.lisp
core.lisp          ; plot/mapping/layer classes + add/composition
aes.lisp
build.lisp
stats/
stat-identity.lisp
stat-count.lisp
stat-bin.lisp
geoms/
geom-point.lisp
geom-line.lisp
geom-bar.lisp
scales/
scale-core.lisp
scale-continuous.lisp
scale-discrete.lisp
palettes.lisp
coords/
coord-cartesian.lisp
themes/
theme-core.lisp
theme-minimal.lisp
theme-ggplot2-approx.lisp
render/
renderer-protocol.lisp
renderer-svg.lisp
test/
package.lisp
suite.lisp
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

Dependencies:
- `cl-tibble`, `cl-vctrs-lite`, `fiveam`
- optionally later: `cl-ppcre` (regex), `alexandria`, a color lib

---

## 14. Milestones (implementation plan)

### M0 — Scaffold
- ASDF systems (`cl-ggplot2`, `cl-ggplot2/test`)
- Roswell test runner, Makefile, smoke test
- empty renderer SVG module stub

Acceptance: `make test` prints OK.

### M1 — Core objects + composition
- plot/mapping/layer classes
- `ggplot`, `aes`, `add` (or `+`) to attach layers/modifiers
- basic validation (mapping columns exist)

Tests: create plot object and add a layer; verify internal structure.

### M2 — SVG renderer protocol + minimal drawing
- renderer protocol
- SVG renderer draws primitives
- `render` returns SVG string

Tests: render empty plot skeleton.

### M3 — Scales (continuous + discrete) and axis ticks
- train continuous domain from data
- map values to positions
- produce breaks/labels

Tests: scale mapping, breaks.

### M4 — Geom point (stat identity)
- `geom_point` draws circles at mapped positions
- NA drop behavior

Snapshot: scatter SVG fixture.

### M5 — Geom line (+ grouping)
- line path rendering per group
- default grouping rules

Snapshot: line SVG fixture.

### M6 — Geom bar + stat count
- count discrete x
- position stacking/dodge later; v0.1: stack only

Snapshot: bar SVG fixture.

### M9 — Color & Fill Scales (Discrete)
Deliver default palettes and categorical color mapping.

### M10 — More Geoms (Histogram, Boxplot)
Full histogram and boxplot support with required stats.

### M11 — Renderer & Styling Polish
Linetypes, legends, and better font control.

### M12 — Faceting
Deliver `facet_wrap`.

Stop here for v0.1 stabilization.

---

## 15. Open design choices (decide early)

1) Composition operator:
   - `add` function is simplest
   - overloading `+` is possible but surprising in CL
   Recommendation: **(add plot ...)**

2) Mapping syntax:
   - accept symbols/keywords naming columns
   - `aes` should store raw “selectors” and resolve against data later

3) Text measurement:
   - for SVG: approximate (good enough for v0.1)
   - for Cairo: need font metrics (later)

---

## 16. Example API (target feel)

```lisp
(let* ((d (cl-tibble:tibble :x #(1 2 3 4)
                            :y #(1 4 9 16)
                            :g #("a" "a" "b" "b"))))
  (cl-ggplot2:save
    (cl-ggplot2:add
      (cl-ggplot2:ggplot d (cl-ggplot2:aes :x :x :y :y :color :g))
      (cl-ggplot2:geom_point)
      (cl-ggplot2:geom_line)
      (cl-ggplot2:theme_ggplot2_approx)
      (cl-ggplot2:labs :title "Demo" :x "x" :y "y"))
    "demo.svg"
    :device :svg :width 600 :height 400))
```

---

## 17. Definition of done (v0.1)

- geom_point, geom_line, geom_bar and histogram work
- SVG output is deterministic and snapshot-tested
- API stable enough to build cl-dplyr pipelines that end in plotting

---

End of SPEC.md
