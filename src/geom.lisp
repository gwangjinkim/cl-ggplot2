(in-package #:cl-ggplot2)

(defgeneric geom-required-aes (geom)
  (:documentation "List of required aesthetics for this geom."))

(defgeneric geom-default-stat (geom)
  (:documentation "Default stat for this geom."))

(defgeneric geom-draw (geom layer-data renderer)
  (:documentation "Draw the geom layer using the renderer and mapped data."))

(defun %get-val (mapped-data key index &optional default)
  (let ((val (gethash key mapped-data)))
    (if (and (typep val 'sequence) (not (stringp val)))
        (if (< index (length val))
            (elt val index)
            default)
        (or val default))))

;;; --- Point ---

(defclass geom-point () ())

(defmethod geom-required-aes ((g geom-point))
  '(:x :y))

(defmethod geom-default-stat ((g geom-point))
  (stat_identity))

(defmethod geom-draw ((g geom-point) layer-data renderer)
  (let ((x-col (gethash :x layer-data))
        (y-col (gethash :y layer-data)))
    (loop for i from 0 below (length x-col)
          for x = (aref x-col i)
          for y = (aref y-col i)
          for color = (%get-val layer-data :color i "black")
          for size = (%get-val layer-data :size i 2.0)
          for alpha = (%get-val layer-data :alpha i 1.0)
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
        ;; For path/line, we use the first value for the whole path in v0.1
        (color (%get-val layer-data :color 0 "black"))
        (size (%get-val layer-data :size 0 1.0))
        (alpha (%get-val layer-data :alpha 0 1.0)))
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

(defmethod geom-draw ((g geom-line) layer-data renderer)
  "geom-line is geom-path but sorts data by x."
  (let* ((x-col (gethash :x layer-data))
         (indices (loop for i from 0 below (length x-col) collect i))
         (sorted-indices (sort indices #'< :key (lambda (i) (aref x-col i))))
         (new-data (make-hash-table)))
    (loop for k being the hash-keys of layer-data using (hash-value v)
          do (if (and (typep v 'sequence) (not (stringp v)))
                 (let ((new-v (make-array (length v) :initial-element (elt v 0))))
                    (loop for i from 0 below (length v)
                          for idx = (elt sorted-indices i)
                          do (setf (aref new-v i) (aref v idx)))
                    (setf (gethash k new-data) new-v))
                 (setf (gethash k new-data) v)))
    (call-next-method g new-data renderer)))


;;; --- Bar/Tile ---

(defclass geom-bar () ())

(defmethod geom-required-aes ((g geom-bar))
  '(:x :y))

(defmethod geom-default-stat ((g geom-bar))
  (stat_count))

(defmethod geom-draw ((g geom-bar) layer-data renderer)
  (let* ((x-col (gethash :x layer-data))
         (y-col (gethash :y layer-data))
         (xmin-col (gethash :xmin layer-data))
         (xmax-col (gethash :xmax layer-data))
         (ymin-col (gethash :ymin layer-data))
         (ymax-col (gethash :ymax layer-data))
         (width (%get-val layer-data :width 0 0.9))
         (px-width (if (> (length x-col) 1)
                       (* width (abs (- (aref x-col 1) (aref x-col 0))))
                       40.0))
         (y-axis-pos (- (r-height renderer) 50)))
    (loop for i from 0 below (length x-col)
          for x = (aref x-col i)
          for y = (aref y-col i)
          for xmin = (when xmin-col (aref xmin-col i))
          for xmax = (when xmax-col (aref xmax-col i))
          for ymin = (when ymin-col (aref ymin-col i))
          for ymax = (when ymax-col (aref ymax-col i))
          for fill = (%get-val layer-data :fill i "#3366cc")
          for color = (%get-val layer-data :color i "none")
          for alpha = (%get-val layer-data :alpha i 1.0)
          unless (or (cl-vctrs-lite:na-p x) (cl-vctrs-lite:na-p y))
          do (r-set-style renderer :fill fill :stroke color :opacity alpha)
             (let ((final-x1 (if xmin xmin (- x (/ px-width 2))))
                   (final-x2 (if xmax xmax (+ x (/ px-width 2))))
                   (final-y1 (if ymax ymax y))
                   (final-y2 (if ymin ymin y-axis-pos)))
               (r-rect renderer final-x1 final-y1 
                       (- final-x2 final-x1) (abs (- final-y2 final-y1)))))))

(defclass geom-tile () ())

(defmethod geom-required-aes ((g geom-tile))
  '(:x :y))

(defmethod geom-default-stat ((g geom-tile))
  (stat_identity))

(defmethod geom-draw ((g geom-tile) layer-data renderer)
  (let ((x-col (gethash :x layer-data))
        (y-col (gethash :y layer-data))
        (width 20.0)
        (height 20.0))
    (loop for i from 0 below (length x-col)
          for x = (aref x-col i)
          for y = (aref y-col i)
          for fill = (%get-val layer-data :fill i "red")
          do (r-set-style renderer :fill fill :stroke "none")
             (r-rect renderer (- x (/ width 2)) (- y (/ height 2)) width height))))

;;; --- Boxplot ---

(defclass geom-boxplot () ())

(defmethod geom-required-aes ((g geom-boxplot))
  '(:y))

(defmethod geom-default-stat ((g geom-boxplot))
  (stat_boxplot))

(defmethod geom-draw ((g geom-boxplot) layer-data renderer)
  (let* ((x-col (gethash :x layer-data))
         (y-col (gethash :y layer-data)) ; Median
         (lower-col (gethash :lower layer-data))
         (upper-col (gethash :upper layer-data))
         (ymin-col (gethash :ymin layer-data))
         (ymax-col (gethash :ymax layer-data)))
    (loop for i from 0 below (length x-col)
          for x = (aref x-col i)
          for mid = (aref y-col i)
          for lower = (aref lower-col i)
          for upper = (aref upper-col i)
          for ymin = (aref ymin-col i)
          for ymax = (aref ymax-col i)
          for fill = (%get-val layer-data :fill i "white")
          for color = (%get-val layer-data :color i "black")
          for alpha = (%get-val layer-data :alpha i 1.0)
          for width = (%get-val layer-data :width i 40.0)
          unless (or (cl-vctrs-lite:na-p x) (cl-vctrs-lite:na-p mid))
          do (r-set-style renderer :fill fill :stroke color :opacity alpha :stroke-width 2)
             ;; Whiskers
             (r-line renderer x ymin x lower)
             (r-line renderer x upper x ymax)
             ;; Box
             (r-rect renderer (- x (/ width 2)) upper width (- lower upper))
             ;; Median line
             (r-set-style renderer :stroke color :stroke-width 3)
             (r-line renderer (- x (/ width 2)) mid (+ x (/ width 2)) mid))))


;;; --- Text/Segment/Rect ---

(defclass geom-text () ())
(defmethod geom-required-aes ((g geom-text)) '(:x :y :label))
(defmethod geom-default-stat ((g geom-text)) (stat_identity))
(defmethod geom-draw ((g geom-text) layer-data renderer)
  (let ((x-col (gethash :x layer-data))
        (y-col (gethash :y layer-data))
        (label-col (gethash :label layer-data)))
    (loop for i from 0 below (length x-col)
          for x = (aref x-col i)
          for y = (aref y-col i)
          for label = (aref label-col i)
          for color = (%get-val layer-data :color i "black")
          for size = (%get-val layer-data :size i 12.0)
          for alpha = (%get-val layer-data :alpha i 1.0)
          unless (or (cl-vctrs-lite:na-p x) (cl-vctrs-lite:na-p y))
          do (r-set-style renderer :fill color :opacity alpha)
             (r-text renderer x y (format nil "~a" label) :font-size size :anchor "middle"))))

(defclass geom-segment () ())
(defmethod geom-required-aes ((g geom-segment)) '(:x :y :xend :yend))
(defmethod geom-default-stat ((g geom-segment)) (stat_identity))
(defmethod geom-draw ((g geom-segment) layer-data renderer)
  (let ((x-col (gethash :x layer-data))
        (y-col (gethash :y layer-data))
        (xend-col (gethash :xend layer-data))
        (yend-col (gethash :yend layer-data)))
    (loop for i from 0 below (length x-col)
          for x1 = (aref x-col i)
          for y1 = (aref y-col i)
          for x2 = (aref xend-col i)
          for y2 = (aref yend-col i)
          for color = (%get-val layer-data :color i "black")
          for size = (%get-val layer-data :size i 1.0)
          for alpha = (%get-val layer-data :alpha i 1.0)
          unless (or (cl-vctrs-lite:na-p x1) (cl-vctrs-lite:na-p y1)
                     (cl-vctrs-lite:na-p x2) (cl-vctrs-lite:na-p y2))
          do (r-set-style renderer :stroke color :stroke-width size :opacity alpha)
             (r-line renderer x1 y1 x2 y2))))

(defclass geom-rect () ())
(defmethod geom-required-aes ((g geom-rect)) '(:xmin :ymin :xmax :ymax))
(defmethod geom-default-stat ((g geom-rect)) (stat_identity))
(defmethod geom-draw ((g geom-rect) layer-data renderer)
  (let ((xmin-col (gethash :xmin layer-data))
        (ymin-col (gethash :ymin layer-data))
        (xmax-col (gethash :xmax layer-data))
        (ymax-col (gethash :ymax layer-data)))
    (loop for i from 0 below (length xmin-col)
          for x1 = (aref xmin-col i)
          for y1 = (aref ymin-col i)
          for x2 = (aref xmax-col i)
          for y2 = (aref ymax-col i)
          for fill = (%get-val layer-data :fill i "#3366cc")
          for color = (%get-val layer-data :color i "none")
          for alpha = (%get-val layer-data :alpha i 1.0)
          unless (or (cl-vctrs-lite:na-p x1) (cl-vctrs-lite:na-p y1)
                     (cl-vctrs-lite:na-p x2) (cl-vctrs-lite:na-p y2))
          do (r-set-style renderer :fill fill :stroke color :opacity alpha)
             (r-rect renderer (min x1 x2) (min y1 y2) (abs (- x2 x1)) (abs (- y2 y1))))))


;;; --- Constructors ---

(defun geom_point (&rest params &key mapping data &allow-other-keys)
  (let ((p (copy-list params)))
    (remf p :mapping) (remf p :data)
    (make-instance 'layer :geom (make-instance 'geom-point) :stat (stat_identity)
                   :mapping mapping :data data :params p)))

(defun geom_path (&rest params &key mapping data &allow-other-keys)
  (let ((p (copy-list params)))
    (remf p :mapping) (remf p :data)
    (make-instance 'layer :geom (make-instance 'geom-path) :stat (stat_identity)
                   :mapping mapping :data data :params p)))

(defun geom_line (&rest params &key mapping data &allow-other-keys)
  (let ((p (copy-list params)))
    (remf p :mapping) (remf p :data)
    (make-instance 'layer :geom (make-instance 'geom-line) :stat (stat_identity)
                   :mapping mapping :data data :params p)))

(defun geom_bar (&rest params &key mapping data (position :stack) &allow-other-keys)
  (let ((p (copy-list params)))
    (remf p :mapping) (remf p :data) (remf p :position)
    (make-instance 'layer :geom (make-instance 'geom-bar) :stat (stat_count)
                   :position position :mapping mapping :data data :params p)))

(defun geom_histogram (&rest params &key mapping data (position :stack) &allow-other-keys)
  (let ((p (copy-list params)))
    (remf p :mapping) (remf p :data) (remf p :position)
    (make-instance 'layer :geom (make-instance 'geom-bar) :stat (stat_bin)
                   :position position :mapping mapping :data data :params p)))

(defun geom_col (&rest params &key mapping data (position :stack) &allow-other-keys)
  (let ((p (copy-list params)))
    (remf p :mapping) (remf p :data) (remf p :position)
    (make-instance 'layer :geom (make-instance 'geom-bar) :stat (stat_identity)
                   :position position :mapping mapping :data data :params p)))

(defun geom_tile (&rest params &key mapping data &allow-other-keys)
  (let ((p (copy-list params)))
    (remf p :mapping) (remf p :data)
    (make-instance 'layer :geom (make-instance 'geom-tile) :stat (stat_identity)
                   :mapping mapping :data data :params p)))

(defun geom_boxplot (&rest params &key mapping data &allow-other-keys)
  (let ((p (copy-list params)))
    (remf p :mapping) (remf p :data)
    (make-instance 'layer :geom (make-instance 'geom-boxplot) :stat (stat_boxplot)
                   :mapping mapping :data data :params p)))

(defun geom_smooth (&rest params &key mapping data (method :lm) &allow-other-keys)
  (declare (ignore method))
  (let ((p (copy-list params)))
    (remf p :mapping) (remf p :data) (remf p :method)
    (unless (getf p :color) (setf (getf p :color) "#3366cc"))
    (make-instance 'layer :geom (make-instance 'geom-line) :stat (stat_smooth)
                   :mapping mapping :data data :params p)))

(defun geom_text (&rest params &key mapping data &allow-other-keys)
  (let ((p (copy-list params)))
    (remf p :mapping) (remf p :data)
    (make-instance 'layer :geom (make-instance 'geom-text) :stat (stat_identity)
                   :mapping mapping :data data :params p)))

(defun geom_segment (&rest params &key mapping data &allow-other-keys)
  (let ((p (copy-list params)))
    (remf p :mapping) (remf p :data)
    (make-instance 'layer :geom (make-instance 'geom-segment) :stat (stat_identity)
                   :mapping mapping :data data :params p)))

(defun geom_rect (&rest params &key mapping data &allow-other-keys)
  (let ((p (copy-list params)))
    (remf p :mapping) (remf p :data)
    (make-instance 'layer :geom (make-instance 'geom-rect) :stat (stat_identity)
                   :mapping mapping :data data :params p)))

(defun annotate (type &rest args)
  "Create an annotation layer of given type."
  (let* ((geom (ecase (if (stringp type) (intern (string-upcase type) :keyword) type)
                 (:text (make-instance 'geom-text))
                 (:segment (make-instance 'geom-segment))
                 (:rect (make-instance 'geom-rect))
                 (:point (make-instance 'geom-point))))
         (data-plist nil)
         (params nil))
    ;; Split args into data (vectors) and params (scalars)
    (loop for (k v) on args by #'cddr
          do (if (member k '(:x :y :xend :yend :xmin :xmax :ymin :ymax :label))
                 (push (list k (if (typep v 'sequence) v (vector v))) data-plist)
                 (push (list k v) params)))
    (let* ((data-args (apply #'append (nreverse data-plist)))
           (tibble (apply #'cl-tibble:tibble data-args))
           (mapping (make-instance 'mapping)))
      (loop for (k v) on data-args by #'cddr
            do (setf (slot-value mapping (%aes-slot-name k)) (string-downcase (string k))))
      (make-instance 'layer
                     :geom geom
                     :stat (stat_identity)
                     :data tibble
                     :mapping mapping
                     :params (apply #'append (nreverse params))))))
