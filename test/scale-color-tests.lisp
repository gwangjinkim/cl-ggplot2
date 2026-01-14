(in-package #:cl-ggplot2/test)

(in-suite :cl-ggplot2)

(test test-discrete-color-mapping
  (let* ((data (cl-tibble:tibble :x #(1 2 3) :y #(10 20 10) :g #("A" "B" "A")))
         (p (gg (data (aes :x :x :y :y :color :g))
              (geom_point)))
         (output (render p :device :svg)))
    ;; Check for presence of mapped colors from the default palette
    ;; A -> #E41A1C, B -> #377EB8
    (is (cl-ppcre:scan "stroke=\"#E41A1C\"" output))
    (is (cl-ppcre:scan "stroke=\"#377EB8\"" output))
    ;; Should have 3 circles
    (is (= 3 (length (cl-ppcre:all-matches-as-strings "<circle" output))))))

(test test-discrete-fill-mapping
  (let* ((data (cl-tibble:tibble :x #("A" "B") :y #(10 20)))
         (p (gg (data (aes :x :x :y :y :fill :x))
              (geom_bar)))
         (output (render p :device :svg)))
    ;; A -> #E41A1C, B -> #377EB8
    (is (cl-ppcre:scan "fill=\"#E41A1C\"" output))
    (is (cl-ppcre:scan "fill=\"#377EB8\"" output))))

(test test-color-constant-override
  (let* ((data (cl-tibble:tibble :x #(1 2) :y #(10 20) :g #("A" "B")))
         (p (gg (data (aes :x :x :y :y :color :g))
              (geom_point :color "green")))
         (output (render p :device :svg)))
    ;; Mapped color should be overridden by green
    (is (not (cl-ppcre:scan "stroke=\"#E41A1C\"" output)))
    (is (cl-ppcre:scan "stroke=\"green\"" output))))
