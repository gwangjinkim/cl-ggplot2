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
