(in-package #:cl-ggplot2)

(defgeneric geom-required-aes (geom)
  (:documentation "List of required aesthetics for this geom."))

(defgeneric geom-default-stat (geom)
  (:documentation "Default stat for this geom."))

(defgeneric geom-draw (geom layer-data renderer)
  (:documentation "Draw the geom layer using the renderer and mapped data."))

(defclass geom-point () ())

(defmethod geom-required-aes ((g geom-point))
  '(:x :y))

(defmethod geom-default-stat ((g geom-point))
  (stat_identity))

(defmethod geom-draw ((g geom-point) layer-data renderer)
  (let ((x-col (gethash :x layer-data))
        (y-col (gethash :y layer-data))
        (color (or (gethash :color layer-data) "black"))
        (size (or (gethash :size layer-data) 2.0))
        (alpha (or (gethash :alpha layer-data) 1.0)))
    (loop for i from 0 below (length x-col)
          for x = (aref x-col i)
          for y = (aref y-col i)
          unless (or (cl-vctrs-lite:na-p x) (cl-vctrs-lite:na-p y))
          do (r-set-style renderer :fill color :stroke color :opacity alpha)
             (r-circle renderer x y size))))

(defun geom_point (&rest params &key mapping data &allow-other-keys)
  (let ((p (copy-list params)))
    (remf p :mapping)
    (remf p :data)
    (make-instance 'layer
                   :geom (make-instance 'geom-point)
                   :stat (geom-default-stat (make-instance 'geom-point))
                   :mapping mapping
                   :data data
                   :params p)))
