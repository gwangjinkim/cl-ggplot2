(in-package #:cl-ggplot2)

(defun aes (&key x y color fill size shape alpha group linetype)
  (make-instance 'mapping
                 :x x :y y :color color :fill fill
                 :size size :shape shape :alpha alpha
                 :group group :linetype linetype))
