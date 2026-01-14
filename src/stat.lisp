(in-package #:cl-ggplot2)

(defgeneric stat-compute (stat data mapping params)
  (:documentation "Transform data for a layer."))

(defclass stat-identity () ())

(defmethod stat-compute ((s stat-identity) data mapping params)
  (declare (ignore mapping params))
  data)

(defun stat_identity ()
  (make-instance 'stat-identity))
