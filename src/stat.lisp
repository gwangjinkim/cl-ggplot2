(in-package #:cl-ggplot2)

(defgeneric stat-compute (stat data mapping params)
  (:documentation "Transform data for a layer. Returns (values transformed-data changed-aes-plist)."))

(defclass stat-identity () ())

(defmethod stat-compute ((s stat-identity) data mapping params)
  (declare (ignore params))
  (values data nil))

(defun stat_identity ()
  (make-instance 'stat-identity))

(defclass stat-count () ())

(defmethod stat-compute ((s stat-count) data mapping params)
  (declare (ignore params))
  (let* ((x-selector (aes-x mapping))
         (x-col-name (if (keywordp x-selector) (string-downcase (string x-selector)) x-selector))
         (x-vals (cl-tibble:tbl-col data x-col-name))
         (counts (make-hash-table :test #'equal))
         (uniques nil))
    ;; Count frequencies
    (loop for i from 0 below (length x-vals)
          for v = (aref x-vals i)
          unless (cl-vctrs-lite:na-p v)
          do (if (gethash v counts)
                 (incf (gethash v counts))
                 (progn (setf (gethash v counts) 1)
                        (push v uniques))))
    ;; Re-sort uniques for deterministic output (order of appearance)
    (setf uniques (nreverse uniques))
    ;; Build new tibble
    (let ((transformed (cl-tibble:tibble
                        :x (map 'vector #'identity uniques)
                        :y (map 'vector (lambda (v) (gethash v counts)) uniques))))
      ;; Return plist of changed aesthetics
      (values transformed '(:x "x" :y "y")))))

(defun stat_count ()
  (make-instance 'stat-count))

(defclass stat-bin () ())

(defmethod stat-compute ((s stat-bin) data mapping params)
  (let* ((x-selector (aes-x mapping))
         (x-col-name (if (keywordp x-selector) (string-downcase (string x-selector)) x-selector))
         (x-vals (cl-tibble:tbl-col data x-col-name))
         (bins (or (getf params :bins) 30))
         (v-min nil)
         (v-max nil))
    ;; Find range
    (loop for i from 0 below (length x-vals)
          for v = (aref x-vals i)
          unless (cl-vctrs-lite:na-p v)
          do (setf v-min (if v-min (min v-min v) v)
                   v-max (if v-max (max v-max v) v)))
    
    (if (and v-min v-max (> v-max v-min))
        (let* ((range (- v-max v-min))
               (binwidth (/ range bins))
               (counts (make-array bins :initial-element 0))
               (mids (make-array bins))
               (xmins (make-array bins))
               (xmaxs (make-array bins)))
          ;; Initialize bins
          (loop for i from 0 below bins
                for start = (+ v-min (* i binwidth))
                for end = (+ start binwidth)
                do (setf (aref xmins i) start
                         (aref xmaxs i) end
                         (aref mids i) (+ start (/ binwidth 2))))
          ;; Fill bins
          (loop for i from 0 below (length x-vals)
                for v = (aref x-vals i)
                unless (cl-vctrs-lite:na-p v)
                do (let ((bin-idx (floor (- v v-min) binwidth)))
                     (when (>= bin-idx bins) (setf bin-idx (1- bins)))
                     (incf (aref counts bin-idx))))
          ;; Build tibble
          (let ((transformed (cl-tibble:tibble
                              :x mids
                              :y counts
                              :xmin xmins
                              :xmax xmaxs
                              :count (map 'vector #'identity counts))))
            (values transformed '(:x "x" :y "y" :xmin "xmin" :xmax "xmax"))))
        ;; Fallback for empty or single value
        (values (cl-tibble:tibble :x #(0) :y #(0) :xmin #(0) :xmax #(0) :count #(0))
                '(:x "x" :y "y" :xmin "xmin" :xmax "xmax")))))

(defun stat_bin (&rest params)
  (declare (ignore params))
  (make-instance 'stat-bin))

(defclass stat-boxplot () ())

(defun %quantile (vector p)
  (let* ((sorted (sort (copy-seq vector) #'<))
         (n (length sorted)))
    (if (= n 0)
        nil
        (let* ((index (* p (1- n)))
               (low (floor index))
               (high (ceiling index))
               (fraction (- index low)))
          (if (= low high)
              (aref sorted low)
              (+ (* (- 1 fraction) (aref sorted low))
                 (* fraction (aref sorted high))))))))

(defmethod stat-compute ((s stat-boxplot) data mapping params)
  (let* ((y-selector (aes-y mapping))
         (y-col-name (if (keywordp y-selector) (string-downcase (string y-selector)) y-selector))
         (y-vals (cl-tibble:tbl-col data y-col-name))
         (clean-y (remove-if #'cl-vctrs-lite:na-p y-vals)))
    (if (> (length clean-y) 0)
        (let ((q1 (%quantile clean-y 0.25))
              (median (%quantile clean-y 0.5))
              (q3 (%quantile clean-y 0.75))
              (min-val (loop for v across clean-y minimize v))
              (max-val (loop for v across clean-y maximize v)))
          (let ((transformed (cl-tibble:tibble
                              :middle (vector median)
                              :lower (vector q1)
                              :upper (vector q3)
                              :ymin (vector min-val)
                              :ymax (vector max-val)
                              :x (vector 1)))) ; Default x pos for single box
            (values transformed '(:x "x" :y "middle" :lower "lower" :upper "upper" :ymin "ymin" :ymax "ymax"))))
        (values (cl-tibble:tibble :middle #(0) :lower #(0) :upper #(0) :ymin #(0) :ymax #(0) :x #(0))
                '(:x "x" :y "middle" :lower "lower" :upper "upper" :ymin "ymin" :ymax "ymax")))))

(defun stat_boxplot (&rest params)
  (declare (ignore params))
  (make-instance 'stat-boxplot))
