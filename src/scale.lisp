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

(defun default-breaks (domain)
  (destructuring-bind (d-min d-max) domain
    (if (and d-min d-max)
        (let* ((count 5)
               (step (/ (- d-max d-min) (1- count))))
          (loop for i from 0 below count
                for val = (+ d-min (* i step))
                collect (list val (fmt-float val))))
        nil)))

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
         (n (length domain))
         (padding (scale-padding s)))
    (if (> n 0)
        (let* ((total-units (+ n (* 2 (- padding 0.5)) 0)) ; Simple version: each category is 1 unit
               ;; range = [min, max]
               ;; Categorical positions are 1, 2, ..., n
               ;; We map 1 to min + offset, n to max - offset
               (step (if (> n 1) (/ (- range-max range-min) (1- n)) 0)))
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
  (loop for v in (scale-domain s)
        collect (list v (format nil "~a" v))))


;;; --- Constructors ---

(defun scale_x_continuous (&rest args)
  (apply #'make-instance 'scale-continuous :channel :x args))

(defun scale_y_continuous (&rest args)
  (apply #'make-instance 'scale-continuous :channel :y args))

(defun scale_x_discrete (&rest args)
  (apply #'make-instance 'scale-discrete :channel :x args))

(defun scale_y_discrete (&rest args)
  (apply #'make-instance 'scale-discrete :channel :y args))
