(in-package #:cl-ggplot2)

(defgeneric geom-required-aes (geom)
  (:documentation "List of required aesthetics for this geom."))

(defgeneric geom-default-stat (geom)
  (:documentation "Default stat for this geom."))

(defgeneric geom-draw (geom layer-data renderer)
  (:documentation "Draw the geom layer using the renderer and mapped data."))


;;; --- Point ---

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


;;; --- Path/Line ---

(defclass geom-path () ())

(defmethod geom-required-aes ((g geom-path))
  '(:x :y))

(defmethod geom-default-stat ((g geom-path))
  (stat_identity))

(defmethod geom-draw ((g geom-path) layer-data renderer)
  (let ((x-col (gethash :x layer-data))
        (y-col (gethash :y layer-data))
        (color (or (gethash :color layer-data) "black"))
        (size (or (gethash :size layer-data) 1.0))
        (alpha (or (gethash :alpha layer-data) 1.0)))
    (r-set-style renderer :stroke color :fill "none" :stroke-width size :opacity alpha)
    (loop for i from 0 below (1- (length x-col))
          for x1 = (aref x-col i)
          for y1 = (aref y-col i)
          for x2 = (aref x-col (1+ i))
          for y2 = (aref y-col (1+ i))
          unless (or (cl-vctrs-lite:na-p x1) (cl-vctrs-lite:na-p y1)
                     (cl-vctrs-lite:na-p x2) (cl-vctrs-lite:na-p y2))
          do (r-line renderer x1 y1 x2 y2))))

(defclass geom-line (geom-path) ())


;;; --- Bar/Tile ---

(defclass geom-bar () ())

(defmethod geom-required-aes ((g geom-bar))
  '(:x :y))

(defmethod geom-default-stat ((g geom-bar))
  (stat_count))

(defmethod geom-draw ((g geom-bar) layer-data renderer)
  (let ((x-col (gethash :x layer-data))
        (y-col (gethash :y layer-data))
        (fill (or (gethash :fill layer-data) "#3366cc"))
        (color (or (gethash :color layer-data) "none"))
        (alpha (or (gethash :alpha layer-data) 1.0))
        ;; Need width from params or calculated
        (width (or (gethash :width layer-data) 0.9)))
    ;; In mapped terms, width of 0.9 means 90% of the gap between categories
    ;; But here we are already in pixel space. For now, assume a fixed pixel width
    ;; or calculate it from the scale. 
    ;; Hack: if x-col has > 1 point, use 80% of gap. Else use 40px.
    (let* ((px-width (if (> (length x-col) 1)
                         (* width (abs (- (aref x-col 1) (aref x-col 0))))
                         40.0))
           (y-axis-pos (- (r-height renderer) 50)))
      (loop for i from 0 below (length x-col)
            for x = (aref x-col i)
            for y = (aref y-col i)
            unless (or (cl-vctrs-lite:na-p x) (cl-vctrs-lite:na-p y))
            do (r-set-style renderer :fill fill :stroke color :opacity alpha)
               (r-rect renderer (- x (/ px-width 2)) y 
                       px-width (abs (- y-axis-pos y)))))))

(defclass geom-tile () ())

(defmethod geom-required-aes ((g geom-tile))
  '(:x :y))

(defmethod geom-default-stat ((g geom-tile))
  (stat_identity))

(defmethod geom-draw ((g geom-tile) layer-data renderer)
  (let ((x-col (gethash :x layer-data))
        (y-col (gethash :y layer-data))
        (fill (or (gethash :fill layer-data) "red"))
        (width 20.0)
        (height 20.0))
    (loop for i from 0 below (length x-col)
          for x = (aref x-col i)
          for y = (aref y-col i)
          do (r-set-style renderer :fill fill :stroke "none")
             (r-rect renderer (- x (/ width 2)) (- y (/ height 2)) width height))))


;;; --- Constructors ---

(defun geom_point (&rest params &key mapping data &allow-other-keys)
  (let ((p (copy-list params)))
    (remf p :mapping)
    (remf p :data)
    (make-instance 'layer
                   :geom (make-instance 'geom-point)
                   :stat (stat_identity)
                   :mapping mapping
                   :data data
                   :params p)))

(defun geom_path (&rest params &key mapping data &allow-other-keys)
  (let ((p (copy-list params)))
    (remf p :mapping)
    (remf p :data)
    (make-instance 'layer
                   :geom (make-instance 'geom-path)
                   :stat (stat_identity)
                   :mapping mapping
                   :data data
                   :params p)))

(defun geom_line (&rest params &key mapping data &allow-other-keys)
  (let ((p (copy-list params)))
    (remf p :mapping)
    (remf p :data)
    (make-instance 'layer
                   :geom (make-instance 'geom-line)
                   :stat (stat_identity)
                   :mapping mapping
                   :data data
                   :params p)))

(defun geom_bar (&rest params &key mapping data &allow-other-keys)
  (let ((p (copy-list params)))
    (remf p :mapping)
    (remf p :data)
    (make-instance 'layer
                   :geom (make-instance 'geom-bar)
                   :stat (stat_count)
                   :mapping mapping
                   :data data
                   :params p)))

(defun geom_col (&rest params &key mapping data &allow-other-keys)
  "Alias for geom_bar with stat_identity."
  (let ((p (copy-list params)))
    (remf p :mapping)
    (remf p :data)
    (make-instance 'layer
                   :geom (make-instance 'geom-bar)
                   :stat (stat_identity)
                   :mapping mapping
                   :data data
                   :params p)))

(defun geom_tile (&rest params &key mapping data &allow-other-keys)
  (let ((p (copy-list params)))
    (remf p :mapping)
    (remf p :data)
    (make-instance 'layer
                   :geom (make-instance 'geom-tile)
                   :stat (stat_identity)
                   :mapping mapping
                   :data data
                   :params p)))
