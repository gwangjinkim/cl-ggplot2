(in-package #:cl-ggplot2/test)

(in-suite :cl-ggplot2)

(test test-gg-macro-data-keyword
  (let* ((p (gg (data (cl-tibble:tibble :x #(1 2) :y #(3 4)))
              (aes :x :x :y :y)
              (geom_point))))
    (is (typep p 'cl-ggplot2::plot))
    (is (typep (cl-ggplot2::plot-data p) 'cl-tibble:tibble))
    (is (= 2 (length (cl-tibble:tbl-col (cl-ggplot2::plot-data p) "x"))))))

(test test-gg-macro-positional
  (let* ((df (cl-tibble:tibble :x #(1 2) :y #(3 4)))
         (p (gg (df (aes :x :x :y :y))
              (geom_point))))
    (is (typep p 'cl-ggplot2::plot))
    (is (eq df (cl-ggplot2::plot-data p)))))

(test test-gg-macro-minimal
  (let* ((df (cl-tibble:tibble :x #(1 2) :y #(3 4)))
         (p (gg df
              (aes :x :x :y :y)
              (geom_point))))
    (is (typep p 'cl-ggplot2::plot))
    (is (eq df (cl-ggplot2::plot-data p)))))
