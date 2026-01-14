# cl-ggplot2: Grammar of Graphics for Common Lisp

**cl-ggplot2** is a high-level, declarative plotting library for Common Lisp, heavily inspired by R's legendary `ggplot2`. It brings the power and expressiveness of the **Grammar of Graphics** to the Lisp ecosystem, allowing you to build complex visualizations with simple, composable primitives.

> [!NOTE]
> This is a native Common Lisp implementation, not a wrapper around R. It integrates seamlessly with `cl-tibble` and `cl-vctrs-lite`.

---

## Why cl-ggplot2?

For many years, plotting in Common Lisp has often felt like an exercise in imperative drawing—calculate coordinates, call `draw-line`, manage the buffer. `cl-ggplot2` changes that by providing a **declarative DSL**:

1.  **Declarative, not Imperative**: You describe *what* your plot should represent, not *how* to draw every pixel.
2.  **Composable Layers**: Want to add a regression line to a scatter plot? Just add a layer.
3.  **Automatic Scaling**: Stop manually normalizing your data to screen coordinates. `cl-ggplot2` handles the mapping from data-space to pixel-space automatically.
4.  **Flexible Faceting**: Split your data into multiple panels effortlessly with `facet_wrap` and `facet_grid`.
5.  **Lispy Idioms**: Designed to feel natural in Common Lisp while remaining familiar to anyone who has used the R Tidyverse.

---

## ⚡ Quickstart

Constructing a plot is as simple as defining your data, mapping aesthetics (like $x$, $y$, and $color$), and choosing your geometry.

```lisp
(ql:quickload '(:cl-ggplot2 :cl-tibble))

(defparameter *p*
  (cl-ggplot2:gg (data (cl-tibble:tibble :mpg #(21 21 22 21 18 18 14)
                                         :hp  #(110 110 93 110 175 105 245)
                                         :cyl #(6 6 4 6 8 6 8)))
    (aes :x :mpg :y :hp :color :cyl)
    (geom_point :size 5 :alpha 0.7)
    (facet_wrap :cyl)
    (labs :title "Horsepower vs. MPG"
          :subtitle "Grouped by Cylinder Count"
          :x "Miles Per Gallon"
          :y "Horsepower")
    (theme_minimal)))

;; Save to SVG
(cl-ggplot2:save *p* "quickstart.svg" :width 800 :height 600)
```

---

## 🎨 The Tutorial: Thinking in Grammars

If you are new to the Grammar of Graphics, the mental model is centered on building a plot as a collection of independent components.

### 1. The Data
The foundation is always your data. In `cl-ggplot2`, this is usually a `cl-tibble:tibble`.

### 2. The Aesthetics (`aes`)
Aesthetics map variables in your data to visual properties.
- **x, y**: Position.
- **color**: Line or point color.
- **fill**: Bar or area color.
- **size**: Thickness or radius.
- **shape**: Symbol style.

### 3. Layers (`geoms`)
Geoms are the visible objects. You can stack them:
```lisp
(gg (data my-tibble)
  (aes :x :year :y :sales)
  (geom_line :color "blue")   ; Adds a line
  (geom_point :size 3))       ; Overlays points on top
```

### 4. Scales and Coordinates
Scales control *how* mapping happens (e.g., categorical color palettes). Coordinates control the space (e.g., `coord_flip` to rotate axes).

### 5. Faceting
Faceting creates sub-plots based on a categorical variable.
- `facet_wrap`: Arranges panels in a sequence.
- `facet_grid`: Arranges panels in a 2D matrix (rows and columns).

---

## 🚀 Extensive Use Case Examples

### Continuous Comparison with Color
Map a categorical variable to color to see groupings in a scatter plot.

```lisp
(gg (data iris)
  (aes :x :sepal-length :y :sepal-width :color :species)
  (geom_point)
  (scale_color_brewer :palette "Set1"))
```

### Discrete Counts with Bar Charts
When you don't provide a `:y` aesthetic to `geom_bar`, it automatically uses the `count` stat to tally occurrences.

```lisp
(gg (data student-data)
  (aes :x :class-year :fill :major)
  (geom_bar :position :dodge) ; Side-by-side bars
  (theme_minimal))
```

### Multi-panel Grid Layouts (Milestone 18+)
Use `facet_grid` to analyze interactions between two categorical variables.

```lisp
(gg (data experiment-results)
  (aes :x :time :y :value)
  (geom_line)
  (facet_grid :rows :treatment :cols :subject)
  (scale_y_continuous :limits '(0 100)))
```

### Visualizing Density
Use `geom_histogram` or `geom_tile` for frequency data or heatmaps.

```lisp
;; Simple Histogram
(gg (data values)
  (aes :x :val)
  (geom_histogram :bins 30))

;; Heatmap
(gg (data matrix)
  (aes :x :row :y :col :fill :z)
  (geom_tile))
```

---

## 📝 Feature Reference

| Component | Fully Supported |
| :--- | :--- |
| **Geoms** | `geom_point`, `geom_line`, `geom_bar`, `geom_col`, `geom_tile`, `geom_histogram`, `geom_boxplot`, `geom_smooth`. |
| **Stats** | `identity`, `count`, `bin`, `boxplot`, `smooth`. |
| **Scales** | Continuous, Discrete, Manual, ColorBrewer. |
| **Facets** | `facet_wrap`, `facet_grid` (with free scale support). |
| **Coordinates** | `coord_cartesian`, `coord_flip`, `coord_fixed`. |
| **Themes** | `theme_minimal`. |

---

## 🛠 Installation

`cl-ggplot2` is designed for modern Common Lisp environments.

**Requirements**: `sbcl`, `roswell`.

```lisp
;; Coming soon to Quicklisp!
;; For now, clone into local-projects:
;; git clone https://github.com/josephus/cl-ggplot2.git
(ql:quickload :cl-ggplot2)
```

---

## 🤝 Contributing

We welcome contributions! To run the test suite:

```bash
make test
```

*cl-ggplot2 is MIT Licensed.*
