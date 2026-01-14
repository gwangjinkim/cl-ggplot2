(in-package #:cl-ggplot2/test)

(in-suite :cl-ggplot2)

(test test-geom-bar-stat-count
  (let* ((data (cl-tibble:tibble :x #("A" "A" "B" "A" "C")))
         (p (gg (data (aes :x :x))
              (geom_bar)))
         (output (render p :device :svg)))
     ;; With stacking, bars start from 0. Scale learns (0 3).
    ;; y=3 maps to 50. y=0 maps to 350. height 300.
    ;; y=1 maps to 250. y=0 maps to 350. height 100.
    (is (= 5 (length (cl-ppcre:all-matches-as-strings "<rect" output))))
    (is (cl-ppcre:scan "height=\"300.0\"" output))
    (is (cl-ppcre:scan "height=\"100.0\"" output))))

(test test-geom-col
  (let* ((data (cl-tibble:tibble :x #("A" "B") :y #(10 20)))
         (p (gg (data (aes :x :x :y :y))
              (geom_col)))
         (output (render p :device :svg)))
    (is (= 4 (length (cl-ppcre:all-matches-as-strings "<rect" output))))))

(test test-geom-tile
  (let* ((data (cl-tibble:tibble :x #(1 2) :y #(1 2)))
         (p (gg (data (aes :x :x :y :y))
              (geom_tile)))
         (output (render p :device :svg)))
    (is (= 4 (length (cl-ppcre:all-matches-as-strings "<rect" output))))
    (is (cl-ppcre:scan "fill=\"red\"" output))))
