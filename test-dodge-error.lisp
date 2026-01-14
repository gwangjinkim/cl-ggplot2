(asdf:load-system :cl-ggplot2)
(in-package #:cl-ggplot2)

(let* ((pos (position_dodge))
       (data (make-hash-table)))
  (setf (gethash :x data) #("A" "A" "B" "B"))
  (setf (gethash :y data) #(10 20 30 40))
  (setf (gethash :fill data) #("X" "Y" "X" "Y"))
  (handler-case
      (progn
        (position-adjust pos data nil)
        (format t "xmin: ~a~%" (gethash :xmin data))
        (format t "xmax: ~a~%" (gethash :xmax data)))
    (error (c) (format t "Caught error: ~a~%" c))))
