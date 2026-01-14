(in-package #:cl-ggplot2)

(defclass facet-base ()
  ((scales :initarg :scales :initform :fixed :accessor facet-scales)))

(defclass facet-wrap (facet-base)
  ((facets :initarg :facets :accessor facet-facets)
   (ncol :initarg :ncol :initform nil :accessor facet-ncol)))

(defclass facet-grid (facet-base)
  ((rows :initarg :rows :initform nil :accessor facet-rows)
   (cols :initarg :cols :initform nil :accessor facet-cols)))

(defun facet_wrap (facets &key ncol (scales :fixed))
  (make-instance 'facet-wrap :facets facets :ncol ncol :scales scales))

(defun facet_grid (&key rows cols (scales :fixed))
  (make-instance 'facet-grid :rows rows :cols cols :scales scales))

(defmethod apply-to-plot ((f facet-base) (p plot))
  (setf (plot-facet p) f)
  p)
