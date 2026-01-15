(in-package #:cl-ggplot2/test)

(in-suite :cl-ggplot2)

(test test-svg-renderer-primitives
  (let ((r (make-instance 'cl-ggplot2::svg-renderer)))
    (cl-ggplot2::r-begin r 100 100)
    (cl-ggplot2::r-set-style r :stroke "red" :fill "blue")
    (cl-ggplot2::r-rect r 10 10 20 20)
    (cl-ggplot2::r-circle r 50 50 5)
    (let ((output (cl-ggplot2::r-end r)))
      (is (cl-ppcre:scan "<svg" output))
      (is (cl-ppcre:scan "rect x=\"10.0\" y=\"10.0\" width=\"20.0\" height=\"20.0\" stroke=\"red\" fill=\"blue\"" output))
      (is (cl-ppcre:scan "circle cx=\"50.0\" cy=\"50.0\" r=\"5.0\" stroke=\"red\" fill=\"blue\"" output))
      (is (cl-ppcre:scan "</svg>" output)))))

(test test-render-api-skeleton
  (let* ((p (ggplot nil))
         (output (render p :device :svg :width 600 :height 400)))
    (is (cl-ppcre:scan "viewBox=\"0 0 600.0 400.0\"" output))
    (is (cl-ppcre:scan "<rect" output)) ; panel
    (is (>= (length (cl-ppcre:all-matches-as-strings "<line" output)) 2)))) ; 2 axes

(test test-render-alpha
  (let* ((df (cl-tibble:tibble :x #(1) :y #(1)))
         (p (gg df
              (aes :x :x :y :y)
              (geom_point :alpha 0.5)))
         (output (render p :device :svg)))
    (is (cl-ppcre:scan "opacity=\"0.5\"" output))))
