(in-package #:cl-ggplot2/test)

(in-suite :cl-ggplot2)

(test test-facet-resolution
  (let* ((data (cl-tibble:tibble :x #(1 2 3 4) :y #(10 20 30 40) :gv #("A" "A" "B" "B")))
         (p (gg (data (aes :x :x :y :y))
              (geom_point)
              (facet_wrap :gv)))
         (built (cl-ggplot2::build-plot p 600 400)))
    (is (= 2 (length (getf built :panels))))
    (is (equal "A" (getf (first (getf built :panels)) :value)))
    (is (equal "B" (getf (second (getf built :panels)) :value)))))

(test test-facet-render-svg
  (let* ((data (cl-tibble:tibble :x #(1 2 3 4) :y #(10 20 30 40) :gv #("A" "A" "B" "B")))
         (p (gg (data (aes :x :x :y :y))
              (geom_point)
              (facet_wrap :gv :ncol 2)))
         (output (render p :device :svg)))
    ;; Should have 2 panels (rects)
    (is (cl-ppcre:scan "A" output))
    (is (cl-ppcre:scan "B" output))
    ;; Grid lines / rects for both panels
    (is (>= (length (cl-ppcre:all-matches-as-strings "<rect" output)) 3)))) ; 2 panels + 2 strips + outer? strip is rect too.
