(in-package #:cl-ggplot2/test)

(in-suite :cl-ggplot2)

(test test-geom-path-order
  (let* ((data (cl-tibble:tibble :x #(1.0 3.0 2.0)
                                 :y #(10.0 30.0 20.0)))
         (p (gg (data (aes :x :x :y :y))
              (geom_path)))
         (output (render p :device :svg)))
    ;; Path: 1->3->2.
    ;; 1.0 -> 50, 3.0 -> 430, 2.0 -> 240.
    (is (cl-ppcre:scan "x1=\"50.0\" y1=\"350.0\" x2=\"430.0\" y2=\"50.0\"" output))
    (is (cl-ppcre:scan "x1=\"430.0\" y1=\"50.0\" x2=\"240.0\" y2=\"200.0\"" output))))

(test test-geom-line-sorts
  (let* ((data (cl-tibble:tibble :x #(1.0 3.0 2.0)
                                 :y #(10.0 30.0 20.0)))
         (p (gg (data (aes :x :x :y :y))
              (geom_line)))
         (output (render p :device :svg)))
    ;; Line: sorted 1->2->3.
    (is (cl-ppcre:scan "x1=\"50.0\" y1=\"350.0\" x2=\"240.0\" y2=\"200.0\"" output))
    (is (cl-ppcre:scan "x1=\"240.0\" y1=\"200.0\" x2=\"430.0\" y2=\"50.0\"" output))))
