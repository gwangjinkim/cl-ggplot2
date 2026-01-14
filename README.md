# cl-ggplot2

A Common Lisp plotting library inspired by R’s **ggplot2**. It provides a **Grammar of Graphics** API.

## Features (Current)
- **Grammar of Graphics**: Construct plots using data, aesthetics, and layers.
- **Geoms**: Support for `geom_point`, `geom_line`, `geom_bar`, `geom_tile`, `geom_histogram`, and `geom_boxplot`.
- **Annotations**: Add static context with `annotate()`, `geom_text`, `geom_segment`, and `geom_rect`.
- **Faceting**: Multi-panel plots with `facet_wrap`.
- **Scales**: Automatic data-to-coordinate mapping (Continuous & Discrete), plus support for **ColorBrewer** and manual palettes.
- **Legends**: Automatic legend generation for color, size, and alpha mappings.
- **Positions**: Support for side-by-side (`dodge`) and 100% stacked (`fill`) bars.
- **Coordinates**: Support for `coord_flip` and `coord_fixed`.
- **Themes & Labels**: Support for titles, axis labels, and custom themes (e.g., `theme_minimal`).
- **SVG Output**: Render plots to deterministic SVG files or strings.
- **Lispy DSL**: Use the `gg` macro for declarative plot composition.

## Installation
(Planned via Quicklisp/Ultralisp)

## Quick Start (Conceptual)

```lisp
(cl-ggplot2:gg (dataset (aes :x :mpg :y :hp :color :cyl))
  (geom_point)
  (theme_minimal)
  (labs :title "Horsepower vs. MPG"))
```

## Running Tests
```bash
make test
```

## License
MIT
