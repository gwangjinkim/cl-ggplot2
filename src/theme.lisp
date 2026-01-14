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
   (axis-line-color :initarg :axis-line-color :initform "black" :accessor theme-axis-line-color)
   (grid-color :initarg :grid-color :initform "#ffffff" :accessor theme-grid-color)
   (text-color :initarg :text-color :initform "black" :accessor theme-text-color)))

(defun theme_minimal ()
  (make-instance 'theme
                 :panel-fill "none"
                 :panel-stroke "none"
                 :axis-line-color "#333333"
                 :grid-color "#eeeeee"))

(defmethod apply-to-plot ((t-obj theme) (p plot))
  (setf (plot-theme p) t-obj)
  p)
