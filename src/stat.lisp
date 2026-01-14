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
