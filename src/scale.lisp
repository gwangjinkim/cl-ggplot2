(in-package #:cl-ggplot2)

;;; --- Scale Protocol ---

(defgeneric scale-channel (scale)
  (:documentation "The aesthetic channel this scale handles (e.g., :x, :y, :color)."))

(defgeneric scale-train (scale values)
  (:documentation "Learn the domain from a vector of values."))

(defgeneric scale-map (scale values range-min range-max)
  (:documentation "Map domain values to the output range."))

(defgeneric scale-breaks (scale)
  (:documentation "Return a list of labels for legend/axis."))

(defgeneric scale-clone (scale)
  (:documentation "Create a fresh copy of the scale for independent training."))


;;; --- Base Scale Class ---

(defclass scale-base ()
  ((channel :initarg :channel :accessor scale-channel)
   (name :initarg :name :initform nil :accessor scale-name)
   (guide :initarg :guide :initform t :accessor scale-guide) ; T = show legend
   (domain :initform nil :accessor scale-domain)))


;;; --- Scale Continuous ---

(defclass scale-continuous (scale-base)
  ((limits :initarg :limits :initform nil :accessor scale-limits) ; (min max)
   (domain :initform (list nil nil) :accessor scale-domain)
   (breaks-fn :initarg :breaks-fn :initform 'default-breaks :accessor scale-breaks-fn)))

(defmethod scale-train ((s scale-continuous) values)
  (when (and values (> (length values) 0))
    (let ((v-min nil)
          (v-max nil))
      (loop for i from 0 below (length values)
            for v = (aref values i)
            when (numberp v)
              do (setf v-min (if v-min (min v-min v) v)
                       v-max (if v-max (max v-max v) v)))
      (when v-min
        (destructuring-bind (d-min d-max) (scale-domain s)
          (setf (scale-domain s)
                (list (if d-min (min d-min v-min) v-min)
                      (if d-max (max d-max v-max) v-max)))))))
  s)

(defmethod scale-map ((s scale-continuous) values range-min range-max)
  (destructuring-bind (d-min d-max) (or (scale-limits s) (scale-domain s))
    (if (and d-min d-max (/= d-min d-max))
        (let ((dm (coerce d-min 'double-float))
              (domain-range (coerce (- d-max d-min) 'double-float))
              (output-range (coerce (- range-max range-min) 'double-float)))
          (cl-vctrs-lite:col-map
           (lambda (v)
             (if (or (cl-vctrs-lite:na-p v) (not (numberp v)))
                 cl-vctrs-lite:*na*
                 (+ range-min (* (/ (- (coerce v 'double-float) dm) domain-range) output-range))))
           values))
        (cl-vctrs-lite:col-map (constantly (coerce range-min 'double-float)) values))))

(defun %nice-num (range round)
  (let* ((exponent (floor (log range 10)))
         (fraction (/ range (expt 10 exponent)))
         (nice-fraction (if round
                             (cond ((< fraction 1.5) 1)
                                   ((< fraction 3) 2)
                                   ((< fraction 7) 5)
                                   (t 10))
                             (cond ((<= fraction 1) 1)
                                   ((<= fraction 2) 2)
                                   ((<= fraction 5) 5)
                                   (t 10)))))
    (* nice-fraction (expt 10 exponent))))

(defun default-breaks (domain)
  (destructuring-bind (d-min d-max) domain
    (if (and d-min d-max (not (= d-min d-max)))
        (let* ((range (%nice-num (- d-max d-min) nil))
               (step (%nice-num (/ range 4) t))
               (graph-min (* (floor (/ d-min step)) step))
               (graph-max (* (ceiling (/ d-max step)) step)))
          (loop for val from graph-min to graph-max by step
                collect val))
        (if (and d-min d-max)
            (list d-min)
            nil))))

(defmethod scale-breaks ((s scale-continuous))
  (funcall (scale-breaks-fn s) (or (scale-limits s) (scale-domain s))))


;;; --- Scale Discrete ---

(defclass scale-discrete (scale-base)
  ((padding :initarg :padding :initform 0.5 :accessor scale-padding)))

(defmethod scale-train ((s scale-discrete) values)
  (when (and values (> (length values) 0))
    (let ((current (scale-domain s)))
      (loop for i from 0 below (length values)
            for v = (aref values i)
            unless (or (cl-vctrs-lite:na-p v) (member v current :test #'equal))
            do (setf current (append current (list v))))
      (setf (scale-domain s) current)))
  s)

(defmethod scale-map ((s scale-discrete) values range-min range-max)
  (let* ((domain (scale-domain s))
         (n (length domain))
         (output-range (coerce (- range-max range-min) 'double-float)))
    (if (> n 0)
        (cl-vctrs-lite:col-map
         (lambda (v)
           (if (cl-vctrs-lite:na-p v)
               cl-vctrs-lite:*na*
               (let ((rank (cond ((numberp v) (coerce v 'double-float))
                                 (t (let ((pos (position v domain :test #'equal)))
                                      (if pos (coerce (1+ pos) 'double-float) nil))))))
                 (if rank
                     (+ range-min (* (/ (- rank 0.5d0) (coerce n 'double-float)) output-range))
                     cl-vctrs-lite:*na*))))
         values)
        ;; Fallback for no data
        (cl-vctrs-lite:col-map (constantly (coerce range-min 'double-float)) values))))

(defmethod scale-breaks ((s scale-discrete))
  (scale-domain s))


;;; --- Constructors (Basic) ---

(defun scale_x_continuous (&rest args) (apply #'make-instance 'scale-continuous :channel :x args))
(defun scale_y_continuous (&rest args) (apply #'make-instance 'scale-continuous :channel :y args))
(defun scale_x_discrete (&rest args) (apply #'make-instance 'scale-discrete :channel :x args))
(defun scale_y_discrete (&rest args) (apply #'make-instance 'scale-discrete :channel :y args))

;;; --- Color & Fill Discrete ---

(defparameter *default-categorical-palette*
  '("#E41A1C" "#377EB8" "#4DAF4A" "#984EA3" "#FF7F00" "#FFFF33" "#A65628" "#F781BF" "#999999"))

(defclass scale-color-discrete (scale-discrete) ())
(defclass scale-fill-discrete (scale-discrete) ())

(defmethod scale-map ((s scale-color-discrete) values range-min range-max)
  (declare (ignore range-min range-max))
  (let* ((domain (scale-domain s))
         (palette *default-categorical-palette*)
         (n-palette (length palette)))
    (cl-vctrs-lite:col-map
     (lambda (v)
       (if (cl-vctrs-lite:na-p v)
           cl-vctrs-lite:*na*
           (let ((idx (position v domain :test #'equal)))
             (if idx
                 (nth (mod idx n-palette) palette)
                 "#cccccc"))))
     values)))

(defmethod scale-map ((s scale-fill-discrete) values range-min range-max)
  (declare (ignore range-min range-max))
  (let* ((domain (scale-domain s))
         (palette *default-categorical-palette*)
         (n-palette (length palette)))
    (cl-vctrs-lite:col-map
     (lambda (v)
       (if (cl-vctrs-lite:na-p v)
           cl-vctrs-lite:*na*
           (let ((idx (position v domain :test #'equal)))
             (if idx
                 (nth (mod idx n-palette) palette)
                 "#cccccc"))))
     values)))

(defun scale_color_discrete (&rest args) (apply #'make-instance 'scale-color-discrete :channel :color args))
(defun scale_fill_discrete (&rest args) (apply #'make-instance 'scale-fill-discrete :channel :fill args))

;;; --- Manual Scales ---

(defclass scale-color-manual (scale-discrete)
  ((values :initarg :values :accessor scale-manual-values)))

(defmethod scale-map ((s scale-color-manual) values range-min range-max)
  (declare (ignore range-min range-max))
  (let* ((domain (scale-domain s))
         (palette (scale-manual-values s)))
    (cl-vctrs-lite:col-map
     (lambda (v)
       (if (cl-vctrs-lite:na-p v)
           cl-vctrs-lite:*na*
           (let ((idx (position v domain :test #'equal)))
             (if idx (nth (mod idx (length palette)) palette) "#cccccc"))))
     values)))

(defun scale_color_manual (&rest args) (apply #'make-instance 'scale-color-manual :channel :color args))

(defclass scale-fill-manual (scale-color-manual) ())
(defun scale_fill_manual (&rest args) (apply #'make-instance 'scale-fill-manual :channel :fill args))

;;; --- Brewer Scales ---

(defparameter *brewer-palettes*
  '(("Set1" . ("#E41A1C" "#377EB8" "#4DAF4A" "#984EA3" "#FF7F00" "#FFFF33" "#A65628" "#F781BF" "#999999"))
    ("Dark2" . ("#1B9E77" "#D95F02" "#7570B3" "#E7298A" "#66A61E" "#E6AB02" "#A6761D" "#666666"))
    ("Paired" . ("#A6CEE3" "#1F78B4" "#B2DF8A" "#33A02C" "#FB9A99" "#E31A1C" "#FDBF6F" "#FF7F00" "#CAB2D6" "#6A3D9A" "#FFFF99" "#B15928"))))

(defclass scale-color-brewer (scale-discrete)
  ((palette-name :initarg :palette :initform "Set1" :accessor scale-palette-name)))

(defmethod scale-map ((s scale-color-brewer) values range-min range-max)
  (declare (ignore range-min range-max))
  (let* ((domain (scale-domain s))
         (palette (cdr (assoc (scale-palette-name s) *brewer-palettes* :test #'equal)))
         (n-palette (length palette)))
    (cl-vctrs-lite:col-map
     (lambda (v)
       (if (cl-vctrs-lite:na-p v)
           cl-vctrs-lite:*na*
           (let ((idx (position v domain :test #'equal)))
             (if idx (nth (mod idx n-palette) palette) "#cccccc"))))
     values)))

(defun scale_color_brewer (&rest args) (apply #'make-instance 'scale-color-brewer :channel :color args))

(defclass scale-fill-brewer (scale-color-brewer) ())
(defun scale_fill_brewer (&rest args) (apply #'make-instance 'scale-fill-brewer :channel :fill args))

;;; --- Size & Alpha (Continuous) ---

(defclass scale-size-continuous (scale-continuous) ())
(defclass scale-alpha-continuous (scale-continuous) ())

(defmethod scale-map ((s scale-size-continuous) values range-min range-max)
  (declare (ignore range-min range-max))
  (call-next-method s values 1.0 6.0))

(defmethod scale-map ((s scale-alpha-continuous) values range-min range-max)
  (declare (ignore range-min range-max))
  (call-next-method s values 0.1 1.0))

(defun scale_size_continuous (&rest args) (apply #'make-instance 'scale-size-continuous :channel :size args))
(defun scale_alpha_continuous (&rest args) (apply #'make-instance 'scale-alpha-continuous :channel :alpha args))

;;; --- Shape (Discrete) ---

(defparameter *default-shape-palette* #(1 2 3 4 5 6))

(defclass scale-shape-discrete (scale-discrete) ())

(defmethod scale-map ((s scale-shape-discrete) values range-min range-max)
  (declare (ignore range-min range-max))
  (let* ((domain (scale-domain s))
         (palette *default-shape-palette*)
         (n-palette (length palette)))
    (cl-vctrs-lite:col-map
     (lambda (v)
       (if (cl-vctrs-lite:na-p v)
           cl-vctrs-lite:*na*
           (let ((idx (position v domain :test #'equal)))
             (if idx (elt palette (mod idx n-palette)) 1))))
     values)))

(defun scale_shape_discrete (&rest args) (apply #'make-instance 'scale-shape-discrete :channel :shape args))

;;; --- Cloning ---

(defmethod scale-clone ((s scale-continuous))
  (make-instance (class-of s)
                 :channel (scale-channel s)
                 :name (scale-name s)
                 :guide (scale-guide s)
                 :limits (scale-limits s)
                 :breaks-fn (scale-breaks-fn s)))

(defmethod scale-clone ((s scale-discrete))
  (make-instance (class-of s)
                 :channel (scale-channel s)
                 :name (scale-name s)
                 :guide (scale-guide s)
                 :padding (scale-padding s)))

(defmethod scale-clone ((s scale-color-manual))
  (make-instance (class-of s)
                 :channel (scale-channel s)
                 :name (scale-name s)
                 :guide (scale-guide s)
                 :values (scale-manual-values s)))

(defmethod scale-clone ((s scale-color-brewer))
  (make-instance (class-of s)
                 :channel (scale-channel s)
                 :name (scale-name s)
                 :guide (scale-guide s)
                 :palette (scale-palette-name s)))
