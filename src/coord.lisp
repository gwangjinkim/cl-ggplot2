(in-package #:cl-ggplot2)

;;; --- Coordinate System Base Class & Protocol ---

(defclass coord-adj () ())

(defgeneric coord-map-scales (coord scales p-x p-y p-w p-h)
  (:documentation "Allows coordinates to adjust scale ranges or limits before mapping."))

(defgeneric coord-transform-mapped (coord mapped-data)
  (:documentation "Final transformation of mapped aesthetics (e.g. swapping x/y for flipped coords)."))

;;; --- Cartesian (Default) ---

(defclass coord-cartesian (coord-adj) ())

(defun coord_cartesian () (make-instance 'coord-cartesian))

(defmethod coord-map-scales ((c coord-cartesian) scales p-x p-y p-w p-h)
  "Default cartesian mapping: X maps to [p-x, p-x+p-w], Y maps to [p-y+p-h, p-y]."
  (declare (ignore c scales))
  (list :x-range (list p-x (+ p-x p-w))
        :y-range (list (+ p-y p-h) p-y)))

(defmethod coord-transform-mapped ((c coord-cartesian) mapped-data)
  mapped-data)


;;; --- Flipped Coordinates ---

(defclass coord-flip (coord-adj) ())

(defun coord_flip () (make-instance 'coord-flip))

(defmethod coord-map-scales ((c coord-flip) scales p-x p-y p-w p-h)
  "Flipped coordinates: X is mapped to vertical range, Y to horizontal range."
  (declare (ignore c scales))
  ;; Logical X channel still uses x-scale, but we map it to vertical range.
  ;; Logical Y channel still uses y-scale, but we map it to horizontal range.
  (list :x-range (list (+ p-y p-h) p-y) ; Vertical
        :y-range (list p-x (+ p-x p-w))))   ; Horizontal

(defmethod coord-transform-mapped ((c coord-flip) mapped-data)
  "Swap X and Y aesthetics in the final mapped data."
  (let* ((old-x (gethash :x mapped-data))
         (old-y (gethash :y mapped-data))
         (old-xmin (gethash :xmin mapped-data))
         (old-xmax (gethash :xmax mapped-data))
         (old-ymin (gethash :ymin mapped-data))
         (old-ymax (gethash :ymax mapped-data)))
    ;; X -> Y (visual vertical)
    ;; Y -> X (visual horizontal)
    (setf (gethash :x mapped-data) old-y)
    (setf (gethash :y mapped-data) old-x)
    ;; Rects: swap xmin/xmax with ymin/ymax
    (setf (gethash :xmin mapped-data) old-ymin)
    (setf (gethash :xmax mapped-data) old-ymax)
    (setf (gethash :ymin mapped-data) old-xmin)
    (setf (gethash :ymax mapped-data) old-xmax)
    mapped-data))


;;; --- Fixed Coordinates ---

(defclass coord-fixed (coord-adj)
  ((ratio :initarg :ratio :initform 1 :accessor coord-ratio)))

(defun coord_fixed (&key (ratio 1)) 
  (make-instance 'coord-fixed :ratio ratio))

(defmethod coord-map-scales ((c coord-fixed) scales p-x p-y p-w p-h)
  "Fixed coordinates: adjusts ranges to maintain aspect ratio."
  (let* ((x-scale (gethash :x scales))
         (y-scale (gethash :y scales))
         (x-dom (scale-domain x-scale))
         (y-dom (scale-domain y-scale)))
    (destructuring-bind (x-min x-max) (or (scale-limits x-scale) x-dom)
      (destructuring-bind (y-min y-max) (or (scale-limits y-scale) y-dom)
        (let* ((x-range (abs (- x-max x-min)))
               (y-range (abs (- y-max y-min)))
               (target-ratio (coord-ratio c))
               (panel-ratio (/ p-h p-w)))
          (declare (ignore x-range y-range))
          ;; Enforce fixed ratio logic: 1 unit on x = ratio unit on y in pixels.
          (if (> (/ panel-ratio target-ratio) 1)
              ;; Panel is too tall, shrink Y pixel range
              (let* ((new-h (* p-w target-ratio))
                     (offset (/ (- p-h new-h) 2)))
                (list :x-range (list p-x (+ p-x p-w))
                      :y-range (list (+ p-y offset new-h) (+ p-y offset))))
              ;; Panel is too wide, shrink X pixel range
              (let* ((new-w (/ p-h target-ratio))
                     (offset (/ (- p-w new-w) 2)))
                (list :x-range (list (+ p-x offset) (+ p-x offset new-w))
                      :y-range (list (+ p-y p-h) p-y)))))))))

(defmethod coord-transform-mapped ((c coord-fixed) mapped-data)
  mapped-data)
