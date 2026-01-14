(in-package #:cl-ggplot2)

;;; --- Scale Protocol ---

(defgeneric scale-channel (scale)
  (:documentation "The aesthetic channel this scale handles (e.g., :x, :y, :color)."))

(defgeneric scale-train (scale values)
  (:documentation "Learn the domain from a vector of values."))

(defgeneric scale-map (scale values range-min range-max)
  (:documentation "Map domain values to the output range."))

(defgeneric scale-breaks (scale)
  (:documentation "Return a list of (value label) for axis ticks."))


;;; --- Scale Continuous ---

(defclass scale-continuous ()
  ((channel :initarg :channel :accessor scale-channel)
   (name :initarg :name :initform nil :accessor scale-name)
   (limits :initarg :limits :initform nil :accessor scale-limits) ; (min max)
   (domain :initform (list nil nil) :accessor scale-domain)
   (breaks-fn :initarg :breaks-fn :initform 'default-breaks :accessor scale-breaks-fn)))

(defmethod scale-train ((s scale-continuous) values)
  (when (and values (> (length values) 0))
    (let ((v-min nil)
          (v-max nil))
      (loop for i from 0 below (length values)
            for v = (aref values i)
            unless (cl-vctrs-lite:na-p v)
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
        (let ((domain-range (- d-max d-min))
              (output-range (- range-max range-min)))
          (cl-vctrs-lite:col-map
           (lambda (v)
             (if (cl-vctrs-lite:na-p v)
                 cl-vctrs-lite:*na*
                 (+ range-min (* (/ (- v d-min) domain-range) output-range))))
           values))
        ;; Fallback for single value or no data
        (cl-vctrs-lite:col-map (constantly range-min) values))))

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

(defclass scale-discrete ()
  ((channel :initarg :channel :accessor scale-channel)
   (name :initarg :name :initform nil :accessor scale-name)
   (domain :initform nil :accessor scale-domain) ; List of unique values
   (padding :initarg :padding :initform 0.5 :accessor scale-padding)))

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
         (n (length domain)))
    (if (> n 0)
        (let ((step (if (> n 1) (/ (- range-max range-min) (1- n)) 0)))
          (cl-vctrs-lite:col-map
           (lambda (v)
             (if (cl-vctrs-lite:na-p v)
                 cl-vctrs-lite:*na*
                 (let ((idx (position v domain :test #'equal)))
                   (if idx
                       (+ range-min (* idx step))
                       cl-vctrs-lite:*na*))))
           values))
        (cl-vctrs-lite:col-map (constantly range-min) values))))

(defmethod scale-breaks ((s scale-discrete))
  (scale-domain s))


;;; --- Constructors ---

(defun scale_x_continuous (&rest args)
  (apply #'make-instance 'scale-continuous :channel :x args))

(defun scale_y_continuous (&rest args)
  (apply #'make-instance 'scale-continuous :channel :y args))

(defun scale_x_discrete (&rest args)
  (apply #'make-instance 'scale-discrete :channel :x args))

(defun scale_y_discrete (&rest args)
  (apply #'make-instance 'scale-discrete :channel :y args))

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
                 "#cccccc")))) ; Fallback
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
                 "#cccccc")))) ; Fallback
     values)))

(defun scale_color_discrete (&rest args)
  (apply #'make-instance 'scale-color-discrete :channel :color args))

(defun scale_fill_discrete (&rest args)
  (apply #'make-instance 'scale-fill-discrete :channel :fill args))
