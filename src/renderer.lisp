(in-package #:cl-ggplot2)

;;; --- Renderer Protocol ---

(defgeneric r-begin (renderer width height)
  (:documentation "Initialize the rendering session."))

(defgeneric r-end (renderer)
  (:documentation "Finalize the rendering session and return the result."))

(defgeneric r-set-style (renderer &key stroke fill stroke-width opacity)
  (:documentation "Set current drawing style."))

(defgeneric r-rect (renderer x y width height)
  (:documentation "Draw a rectangle."))

(defgeneric r-line (renderer x1 y1 x2 y2)
  (:documentation "Draw a line."))

(defgeneric r-circle (renderer cx cy radius)
  (:documentation "Draw a circle."))

(defgeneric r-text (renderer x y text &key anchor angle font-size font-family)
  (:documentation "Draw text."))

(defgeneric r-group-begin (renderer &key id class)
  (:documentation "Begin a group of elements."))

(defgeneric r-group-end (renderer)
  (:documentation "End a group of elements."))


;;; --- SVG Renderer Implementation ---

(defclass svg-renderer ()
  ((width :initarg :width :accessor r-width)
   (height :initarg :height :accessor r-height)
   (stream :initform (make-string-output-stream) :accessor r-stream)
   (style :initform nil :accessor r-style)))

(defun fmt-float (x)
  "Deterministic float formatting for SVG/snapshots."
  (if (integerp x)
      (format nil "~d" x)
      (let ((s (format nil "~,3f" (coerce x 'double-float))))
        ;; Trim trailing zeros but keep one if it is .0
        (let ((trimmed (string-right-trim "0" s)))
          (if (string-equal "." (subseq trimmed (1- (length trimmed))))
              (concatenate 'string trimmed "0")
              trimmed)))))

(defmethod r-begin ((r svg-renderer) width height)
  (setf (r-width r) width (r-height r) height)
  (let ((s (r-stream r)))
    (format s "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>~%")
    (format s "<svg width=\"~a\" height=\"~a\" viewBox=\"0 0 ~a ~a\" xmlns=\"http://www.w3.org/2000/svg\">~%"
            (fmt-float width) (fmt-float height) (fmt-float width) (fmt-float height))))

(defmethod r-end ((r svg-renderer))
  (let ((s (r-stream r)))
    (format s "</svg>~%")
    (get-output-stream-string s)))

(defun %svg-style-to-attrs (style)
  (with-output-to-string (s)
    (destructuring-bind (&key stroke fill stroke-width opacity) style
      (when stroke (format s " stroke=\"~a\"" stroke))
      (when fill (format s " fill=\"~a\"" fill))
      (when stroke-width (format s " stroke-width=\"~a\"" (fmt-float stroke-width)))
      (when opacity (format s " opacity=\"~a\"" (fmt-float opacity))))))

(defmethod r-set-style ((r svg-renderer) &rest style)
  (setf (r-style r) style))

(defmethod r-rect ((r svg-renderer) x y width height)
  (format (r-stream r) "<rect x=\"~a\" y=\"~a\" width=\"~a\" height=\"~a\"~a />~%"
          (fmt-float x) (fmt-float y) (fmt-float width) (fmt-float height)
          (%svg-style-to-attrs (r-style r))))

(defmethod r-line ((r svg-renderer) x1 y1 x2 y2)
  (format (r-stream r) "<line x1=\"~a\" y1=\"~a\" x2=\"~a\" y2=\"~a\"~a />~%"
          (fmt-float x1) (fmt-float y1) (fmt-float x2) (fmt-float y2)
          (%svg-style-to-attrs (r-style r))))

(defmethod r-circle ((r svg-renderer) cx cy radius)
  (format (r-stream r) "<circle cx=\"~a\" cy=\"~a\" r=\"~a\"~a />~%"
          (fmt-float cx) (fmt-float cy) (fmt-float radius)
          (%svg-style-to-attrs (r-style r))))

(defmethod r-text ((r svg-renderer) x y text &key anchor angle font-size font-family)
  (format (r-stream r) "<text x=\"~a\" y=\"~a\"~a~a~a~a>~a</text>~%"
          (fmt-float x) (fmt-float y)
          (if anchor (format nil " text-anchor=\"~a\"" anchor) "")
          (if angle (format nil " transform=\"rotate(~a ~a ~a)\"" (fmt-float angle) (fmt-float x) (fmt-float y)) "")
          (if font-size (format nil " font-size=\"~a\"" (fmt-float font-size)) "")
          (if font-family (format nil " font-family=\"~a\"" font-family) "")
          text))

(defmethod r-group-begin ((r svg-renderer) &key id class)
  (format (r-stream r) "<g~a~a>~%"
          (if id (format nil " id=\"~a\"" id) "")
          (if class (format nil " class=\"~a\"" class) "")))

(defmethod r-group-end ((r svg-renderer))
  (format (r-stream r) "</g>~%"))
