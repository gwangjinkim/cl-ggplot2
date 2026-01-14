(in-package #:cl-ggplot2/test)

(in-suite :cl-ggplot2)

(test test-labs-updates-plot
  (let* ((p (ggplot nil))
         (l (labs :title "My Title" :x "X Axis")))
    (apply-to-plot l p)
    (is (equal "My Title" (cl-ggplot2::plot-title p)))
    (is (equal "X Axis" (cl-ggplot2::plot-x-label p)))))

(test test-theme-minimal
  (let* ((p (ggplot nil))
         (t-obj (theme_minimal)))
    (apply-to-plot t-obj p)
    (is (eq t-obj (cl-ggplot2::plot-theme p)))
    (is (equal "none" (cl-ggplot2::theme-panel-fill t-obj)))))

(test test-render-with-labels
  (let* ((data (cl-tibble:tibble :x #(1 2) :y #(10 20)))
         (p (gg (data (aes :x :x :y :y))
              (geom_point)
              (labs :title "Test Plot" :x "My X" :y "My Y")))
         (output (render p :device :svg)))
    (is (cl-ppcre:scan "Test Plot" output))
    (is (cl-ppcre:scan "My X" output))
    (is (cl-ppcre:scan "My Y" output))
    ;; Should have title text with middle anchor
    (is (cl-ppcre:scan "text-anchor=\"middle\"" output))))
