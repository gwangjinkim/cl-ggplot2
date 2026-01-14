(in-package #:cl-ggplot2)

;;; --- Position Adjustment Classes ---

(defclass position-adj () ())

(defclass position-identity (position-adj) ())

(defclass position-stack (position-adj)
  ((vjust :initarg :vjust :initform 1 :accessor position-vjust)))

(defclass position-fill (position-stack) ())

(defclass position-dodge (position-adj)
  ((width :initarg :width :initform nil :accessor position-width)
   (preserve :initarg :preserve :initform :total :accessor position-preserve)))

;;; --- Public Constructors ---

(defun position_identity () (make-instance 'position-identity))
(defun position_stack (&key (vjust 1)) (make-instance 'position-stack :vjust vjust))
(defun position_fill () (make-instance 'position-fill))
(defun position_dodge (&key width (preserve :total))
  (make-instance 'position-dodge :width width :preserve preserve))

;;; --- Protocol ---

(defgeneric position-adjust (pos data params)
  (:documentation "Adjusts mapped aesthetic coordinates (usually y for stacking/filling, x for dodging)."))

(defmethod position-adjust ((p position-identity) data params)
  (declare (ignore params))
  data)

(defmethod position-adjust ((p position-stack) data params)
  "Stacked positions: updates ymin/ymax if they exist, or creates them. 
   Requires data sorted by x/group."
  (let* ((x (gethash :x data))
         (y (gethash :y data))
         (n (length x))
         (new-ymin (make-array n :element-type 'double-float :initial-element 0.0d0))
         (new-ymax (make-array n :element-type 'double-float :initial-element 0.0d0))
         (sums (make-hash-table :test 'equal))) ; x -> current-sum
    
    (loop for i from 0 below n
          for xi = (aref x i)
          for yi = (aref y i)
          for current-sum = (gethash xi sums 0.0d0)
          do (setf (aref new-ymin i) current-sum)
             (setf (aref new-ymax i) (+ current-sum (coerce yi 'double-float)))
             (setf (gethash xi sums) (aref new-ymax i)))

    (setf (gethash :ymin data) new-ymin)
    (setf (gethash :ymax data) new-ymax)
    data))

(defmethod position-adjust ((p position-fill) data params)
  "Filled positions: same as stacking but scales to [0, 1]."
  (let* ((x (gethash :x data))
         (y (gethash :y data))
         (n (length x))
         (row-totals (make-hash-table :test 'equal)))
    
    ;; 1. Compute totals per X FIRST
    (loop for i from 0 below n
          for xi = (aref x i)
          for yi = (aref y i)
          do (incf (gethash xi row-totals 0.0d0) (coerce yi 'double-float)))

    ;; 2. Use position-stack logic to get ymin/ymax
    (call-next-method)
    
    (let ((ymin (gethash :ymin data))
          (ymax (gethash :ymax data)))
      ;; 3. Scale
      (loop for i from 0 below n
            for xi = (aref x i)
            for total = (gethash xi row-totals)
            do (unless (zerop total)
                 (setf (aref ymin i) (/ (aref ymin i) total))
                 (setf (aref ymax i) (/ (aref ymax i) total)))))
    data))

(defmethod position-adjust ((p position-dodge) data params)
  "Dodged positions: splits bars at the same X side-by-side using width/xmin/xmax."
  (let* ((x (gethash :x data))
         (group (or (gethash :group data) 
                    (gethash :fill data) 
                    (gethash :color data)
                    (make-array (length x) :initial-element 0)))
         (n (length x))
         (new-xmin (make-array n :element-type 'double-float :initial-element 0.0d0))
         (new-xmax (make-array n :element-type 'double-float :initial-element 0.0d0))
         (x-groups (make-hash-table :test 'equal)) ; x -> list of group-indices
         (unique-x (remove-duplicates (coerce x 'list) :test 'equal))
         (x-ranks (make-hash-table :test 'equal)))

    ;; 1. Collect groups per X
    (loop for i from 0 below n
          do (push i (gethash (aref x i) x-groups)))

    ;; 2. Determine numeric ranks for X
    (let ((sorted-x (sort unique-x (lambda (a b) 
                                     (cond ((and (numberp a) (numberp b)) (< a b))
                                           ((numberp a) t)
                                           ((numberp b) nil)
                                           (t (string< (format nil "~a" a) (format nil "~a" b))))))))
      (loop for val in sorted-x
            for i from 1
            do (setf (gethash val x-ranks) (coerce i 'double-float))))

    ;; 3. For each X, distribute groups
    (maphash (lambda (xi indices)
               (let* ((sorted-indices (sort indices #'string< :key (lambda (idx) (format nil "~a" (aref group idx)))))
                      (m (length sorted-indices))
                      (total-width (coerce (or (position-width p) 0.9d0) 'double-float)) ; default bar width
                      (sub-width (/ total-width m))
                      (xi-d (gethash xi x-ranks)))
                 (loop for j from 0 below m
                       for idx = (nth j sorted-indices)
                       for center = (+ (- xi-d (/ total-width 2.0d0)) (* (+ j 0.5d0) sub-width))
                       do (setf (aref new-xmin idx) (- center (/ sub-width 2.0d0)))
                          (setf (aref new-xmax idx) (+ center (/ sub-width 2.0d0))))))
             x-groups)

    (setf (gethash :xmin data) new-xmin)
    (setf (gethash :xmax data) new-xmax)
    data))
