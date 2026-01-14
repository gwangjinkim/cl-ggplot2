(in-package #:cl-ggplot2/test)

(in-suite :cl-ggplot2)

(test test-coord-flip
  (let* ((data (cl-tibble:tibble :x #(1 2) :y #(10 20)))
         (p (gg (data (aes :x :x :y :y))
              (geom_col)
              (coord_flip)))
         (output (render p :device :svg)))
    ;; In a flipped coord, the bars should be horizontal.
    (is (cl-ppcre:scan "width=\"[1-9]" output))
    ;; Verify that rects have non-zero width (horizontal bars)
    (let ((rect-widths (mapcar (lambda (s) 
                                 (cl-ppcre:register-groups-bind (w) ("width=\"([^\"]+)\"" s) 
                                   (read-from-string w)))
                               (cl-ppcre:all-matches-as-strings "width=\"[^\"]+\"" output))))
      (is (find-if (lambda (w) (> w 10)) rect-widths)))))

(test test-coord-fixed
  (let* ((data (cl-tibble:tibble :x #(0 10) :y #(0 10)))
         (p (gg (data (aes :x :x :y :y))
              (geom_point)
              (coord_fixed :ratio 1)))
         ;; Use a non-square output to force adjustment
         (output (render p :device :svg :width 600 :height 400)))
    ;; Point (0,0) -> X=150, Y=350.
    ;; Point (10,10) -> X=450, Y=50.
    (is (cl-ppcre:scan "cx=\"150.0\" cy=\"350.0\"" output))
    (is (cl-ppcre:scan "cx=\"450.0\" cy=\"50.0\"" output))))
