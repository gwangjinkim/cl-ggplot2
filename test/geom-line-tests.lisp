(in-package #:cl-ggplot2/test)

(in-suite :cl-ggplot2)

(test test-geom-path-order
  (let* ((data (cl-tibble:tibble :x #(1.0 3.0 2.0)
                                 :y #(10.0 30.0 20.0)))
         (p (gg (data (aes :x :x :y :y))
              (geom_path)))
         (output (render p :device :svg)))
    ;; Path should follow 1->3->2.
    ;; 1->3 is cx-jump, 3->2 is cx-back.
    ;; With 1.0->50, 2.0->300, 3.0->550.
    ;; Lines should be x1=50 x2=550 and then x1=550 x2=300
    (is (cl-ppcre:scan "x1=\"50.0\" y1=\"350.0\" x2=\"550.0\" y2=\"50.0\"" output))
    (is (cl-ppcre:scan "x1=\"550.0\" y1=\"50.0\" x2=\"300.0\" y2=\"200.0\"" output))))

(test test-geom-line-sorts
  (let* ((data (cl-tibble:tibble :x #(1.0 3.0 2.0)
                                 :y #(10.0 30.0 20.0)))
         (p (gg (data (aes :x :x :y :y))
              (geom_line)))
         (output (render p :device :svg)))
    ;; Line should follow 1->2->3.
    (is (cl-ppcre:scan "x1=\"50.0\" y1=\"350.0\" x2=\"300.0\" y2=\"200.0\"" output))
    (is (cl-ppcre:scan "x1=\"300.0\" y1=\"200.0\" x2=\"550.0\" y2=\"50.0\"" output))))
