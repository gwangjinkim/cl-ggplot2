(in-package #:cl-ggplot2)

(defgeneric apply-to-plot (item plot)
  (:documentation "Apply a layer, scale, theme, or other modifier to a plot."))

(defmethod apply-to-plot ((item layer) (plot plot))
  (setf (plot-layers plot) (append (plot-layers plot) (list item)))
  plot)

(defmethod apply-to-plot ((item scale-continuous) (plot plot))
  (setf (gethash (scale-channel item) (plot-scales plot)) item)
  plot)

(defmethod apply-to-plot ((item scale-discrete) (plot plot))
  (setf (gethash (scale-channel item) (plot-scales plot)) item)
  plot)

(defmethod apply-to-plot ((item coord-adj) (plot plot))
  (setf (plot-coord plot) item)
  plot)

(defmethod apply-to-plot ((item theme) (plot plot))
  (setf (plot-theme plot) item)
  plot)

(defmethod apply-to-plot ((item labs) (plot plot))
  (when (labs-title item) (setf (plot-title plot) (labs-title item)))
  (when (labs-subtitle item) (setf (plot-subtitle plot) (labs-subtitle item)))
  (when (labs-x item) (setf (plot-x-label plot) (labs-x item)))
  (when (labs-y item) (setf (plot-y-label plot) (labs-y item)))
  plot)

(defmethod apply-to-plot ((item facet-wrap) (plot plot))
  (setf (plot-facet plot) item)
  plot)

;; Fallback for NIL (useful in macros)
(defmethod apply-to-plot ((item null) (plot plot))
  plot)
