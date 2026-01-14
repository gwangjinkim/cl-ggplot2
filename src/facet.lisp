(in-package #:cl-ggplot2)

(defclass facet-wrap ()
  ((facets :initarg :facets :accessor facet-facets)
   (ncol :initarg :ncol :initform nil :accessor facet-ncol)))

(defun facet_wrap (facets &key ncol)
  (make-instance 'facet-wrap :facets facets :ncol ncol))

(defmethod apply-to-plot ((f facet-wrap) (p plot))
  (setf (plot-facet p) f)
  p)
