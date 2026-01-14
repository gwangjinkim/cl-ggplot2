(in-package #:cl-ggplot2/test)

(in-suite :cl-ggplot2)

(test test-scatter-plot-render
  (let* ((data (cl-tibble:tibble :x #(1.0 2.0 3.0)
                                 :y #(10.0 20.0 30.0)))
         (p (gg (data (aes :x :x :y :y))
              (geom_point)))
         (output (render p :device :svg :width 600 :height 400)))
    (is (cl-ppcre:scan "<svg" output))
    ;; There should be 3 circles for the 3 points
    (is (= 3 (length (cl-ppcre:all-matches-as-strings "<circle" output))))
    ;; Center of 380 is 190. 50 + 190 = 240.
    (is (cl-ppcre:scan "cx=\"240.0\"" output))))

(test test-scatter-plot-with-params
  (let* ((data (cl-tibble:tibble :x #(1.0) :y #(10.0)))
         (p (gg (data (aes :x :x :y :y))
              (geom_point :color "blue" :size 5.0)))
         (output (render p :device :svg)))
    (is (cl-ppcre:scan "fill=\"blue\"" output))
    (is (cl-ppcre:scan "r=\"5.0\"" output))))
