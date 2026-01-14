(in-package #:cl-ggplot2)

;;; --- Labels ---

(defclass labs ()
  ((title :initarg :title :initform nil :accessor labs-title)
   (subtitle :initarg :subtitle :initform nil :accessor labs-subtitle)
   (x :initarg :x :initform nil :accessor labs-x)
   (y :initarg :y :initform nil :accessor labs-y)))

(defun labs (&key title subtitle x y)
  (make-instance 'labs :title title :subtitle subtitle :x x :y y))

(defmethod apply-to-plot ((l labs) (p plot))
  (when (labs-title l) (setf (plot-title p) (labs-title l)))
  (when (labs-subtitle l) (setf (plot-subtitle p) (labs-subtitle l)))
  (when (labs-x l) (setf (plot-x-label p) (labs-x l)))
  (when (labs-y l) (setf (plot-y-label p) (labs-y l)))
  p)

;;; --- Themes ---

(defclass theme ()
  ((panel-fill :initarg :panel-fill :initform "#f0f0f0" :accessor theme-panel-fill)
   (panel-stroke :initarg :panel-stroke :initform "#cccccc" :accessor theme-panel-stroke)
   (grid-color :initarg :grid-color :initform "#ffffff" :accessor theme-grid-color)
   (grid-color-minor :initarg :grid-color-minor :initform "#f5f5f5" :accessor theme-grid-color-minor)
   (axis-line-color :initarg :axis-line-color :initform "black" :accessor theme-axis-line-color)
   (axis-text-color :initarg :axis-text-color :initform "#333333" :accessor theme-axis-text-color)
   (axis-text-size :initarg :axis-text-size :initform 10 :accessor theme-axis-text-size)
   (axis-tick-color :initarg :axis-tick-color :initform "black" :accessor theme-axis-tick-color)
   (text-color :initarg :text-color :initform "black" :accessor theme-text-color)))

(defun theme_minimal ()
  (make-instance 'theme
                 :panel-fill "none"
                 :panel-stroke "none"
                 :grid-color "#f0f0f0"
                 :grid-color-minor "#f8f8f8"
                 :axis-line-color "#333333"
                 :axis-text-color "#555555"
                 :axis-tick-color "black"))

(defmethod apply-to-plot ((t-obj theme) (p plot))
  (setf (plot-theme p) t-obj)
  p)
