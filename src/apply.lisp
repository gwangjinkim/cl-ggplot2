(in-package #:cl-ggplot2)

(defgeneric apply-to-plot (item plot)
  (:documentation "Apply a layer, scale, theme, or other modifier to a plot."))

(defmethod apply-to-plot ((item layer) (plot plot))
  (setf (plot-layers plot) (append (plot-layers plot) (list item)))
  plot)

;; Fallback for NIL (useful in macros)
(defmethod apply-to-plot ((item null) (plot plot))
  plot)
