# cl-ggplot2

A Common Lisp plotting library inspired by R’s **ggplot2**. It provides a **Grammar of Graphics** API.

## Features (Current)
- **Grammar of Graphics**: Construct plots using data, aesthetics, and layers.
- **Geoms**: Initial support for `geom_point` (scatter plots).
- **Scales**: Automatic data-to-coordinate mapping (Continuous x/y).
- **SVG Output**: Render plots to deterministic SVG files or strings.
- **Lispy DSL**: Use the `gg` macro for declarative plot composition.
- **Composable**: Chain components with the `-+` operator.

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
