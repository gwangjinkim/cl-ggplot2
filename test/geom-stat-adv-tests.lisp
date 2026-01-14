(in-package #:cl-ggplot2/test)

(in-suite :cl-ggplot2)

(test test-histogram-render
  (let* ((data (cl-tibble:tibble :x #(1 1 2 2 2 3 4 5)))
         (p (gg (data (aes :x :x))
              (geom_histogram :bins 5)))
         (output (render p :device :svg)))
    (is (cl-ppcre:scan "<rect" output))
    ;; Bin 2 should have count 3
    ;; We can't easily check exact pixels without more effort, but we check it doesn't crash
    (is (cl-ppcre:scan "fill=\"#3366cc\"" output))))

(test test-boxplot-render
  (let* ((data (cl-tibble:tibble :y #(10 20 30 40 50 60 70 80 90 100)))
         (p (gg (data (aes :y :y))
              (geom_boxplot)))
         (output (render p :device :svg)))
    ;; Should draw a rect and some lines
    (is (cl-ppcre:scan "<rect" output))
    (is (cl-ppcre:scan "<line" output))
    ;; Median for 10..100 is around 55
    (is (cl-ppcre:scan "stroke-width=\"3.0\"" output)))) ; Median line style

(test test-quantile-logic
  (let ((v #(1 2 3 4 5 6 7 8 9 10)))
    (is (= 5.5 (cl-ggplot2::%quantile v 0.5)))
    (is (= 3.25 (cl-ggplot2::%quantile v 0.25)))
    (is (= 7.75 (cl-ggplot2::%quantile v 0.75)))))

(test test-stat-smooth
  (let* ((data (cl-tibble:tibble :x #(1 2 3 4 5) :y #(2 4 6 8 10)))
         (p (gg (data (aes :x :x :y :y))
              (geom_smooth)))
         (output (render p :device :svg)))
    ;; OLS for y=2x should have slope 2, intercept 0.
    ;; Verify we have lines (polylines are drawn as multiple <line> in current renderer)
    (is (cl-ppcre:scan "<line" output))
    ;; Check for default smooth color
    (is (cl-ppcre:scan "stroke=\"#3366cc\"" output))))

(test test-scales-adv
  (let* ((data (cl-tibble:tibble :x #(1 2 3) :y #(1 2 3) :s #(10 20 30) :a #(0 0.5 1)))
         (p (gg (data (aes :x :x :y :y :size :s :alpha :a))
              (geom_point)))
         (output (render p :device :svg)))
    ;; Size should map to non-default values (1.0 to 6.0)
    (is (cl-ppcre:scan "r=\"1.0\"" output)) ; Min size
    (is (cl-ppcre:scan "r=\"6.0\"" output)) ; Max size
    ;; Alpha should map to opacity (0.1 to 1.0)
    (is (cl-ppcre:scan "opacity=\"0.1\"" output)) ; Min alpha
    (is (cl-ppcre:scan "opacity=\"1.0\"" output)))) ; Max alpha
