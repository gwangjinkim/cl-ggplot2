(in-package #:cl-ggplot2/test)

(in-suite :cl-ggplot2)

(test test-facet-grid-layout
  (let* ((df (cl-tibble:tibble :x #(1 2 3 4) :y #(10 20 30 40) 
                                :rv #("R1" "R1" "R2" "R2")
                                :cv #("C1" "C2" "C1" "C2")))
         (p (gg df
              (aes :x :x :y :y)
              (geom_point)
              (facet_grid :rows :rv :cols :cv)))
         (built (cl-ggplot2::build-plot p 600 400)))
    ;; 4 panels in a 2x2 grid
    (is (= 4 (length (getf built :panels))))
    (is (= 2 (getf built :nrow)))
    (is (= 2 (getf built :ncol)))
    ;; Verify first panel (R1, C1)
    (let ((p1 (first (getf built :panels))))
      (is (equal '("R1" "C1") (getf p1 :value)))
      (is (= 0 (getf p1 :row)))
      (is (= 0 (getf p1 :col))))))

(test test-facet-free-scales
  (let* ((df (cl-tibble:tibble :x #(1 2 100 200) :y #(1 1 1 1) :gv #("A" "A" "B" "B")))
         (p (gg df
              (aes :x :x :y :y)
              (geom_point)
              (facet_wrap :gv :scales :free_x)))
         (built (cl-ggplot2::build-plot p 600 400))
         (panels (getf built :panels)))
    ;; Two panels
    (is (= 2 (length panels)))
    ;; Panel A x-scale domain should be [1, 2]
    (let* ((sa (gethash :x (getf (first panels) :scales)))
           (sb (gethash :x (getf (second panels) :scales))))
      (is (equal '(1.0 2.0) (cl-ggplot2::scale-domain sa)))
      (is (equal '(100.0 200.0) (cl-ggplot2::scale-domain sb))))))
