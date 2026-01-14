(in-package #:cl-ggplot2/test)

(in-suite :cl-ggplot2)

(test test-legend-categorical
  (let* ((data (cl-tibble:tibble :x #(1 2 3) :y #(1 2 3) :g #("A" "B" "C")))
         (p (gg (data (aes :x :x :y :y :color :g))
              (geom_point)))
         (output (render p :device :svg)))
    ;; Check for legend title
    (is (cl-ppcre:scan "G" output))
    ;; Check for legend items (A, B, C)
    (is (cl-ppcre:scan "A" output))
    (is (cl-ppcre:scan "B" output))
    (is (cl-ppcre:scan "C" output))
    ;; Should have more than 3 circles (3 points + 3 legend keys if drawn)
    ;; Actually our current legend draws circles for points and rects for color keys?
    ;; Checking code: case :color draws r-rect.
    (is (>= (length (cl-ppcre:all-matches-as-strings "<rect" output)) 4)))) ; 1 panel + 3 legend keys

(test test-scale-color-brewer
  (let* ((data (cl-tibble:tibble :x #(1 2) :g #("A" "B")))
         (p (gg (data (aes :x :x :y :x :color :g))
              (geom_point)
              (scale_color_brewer :palette "Set1")))
         (output (render p :device :svg)))
    ;; Set1 first color is #E41A1C
    (is (cl-ppcre:scan "fill=\"#E41A1C\"" output))))

(test test-scale-color-manual
  (let* ((data (cl-tibble:tibble :x #(1 2) :g #("A" "B")))
         (p (gg (data (aes :x :x :y :x :color :g))
              (geom_point)
              (scale_color_manual :values '("cyan" "magenta"))))
         (output (render p :device :svg)))
    (is (cl-ppcre:scan "fill=\"cyan\"" output))
    (is (cl-ppcre:scan "fill=\"magenta\"" output))))
