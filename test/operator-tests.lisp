(in-package #:cl-ggplot2/test)

(in-suite :cl-ggplot2)

(test test-aes-constructor
  (let ((m (aes :x "mpg" :y "hp" :color "cyl")))
    (is (equal "mpg" (cl-ggplot2::aes-x m)))
    (is (equal "hp" (cl-ggplot2::aes-y m)))
    (is (equal "cyl" (cl-ggplot2::aes-color m)))))

(test test-ggplot-constructor
  (let* ((data '((:mpg . 21) (:hp . 110)))
         (p (ggplot data)))
    (is (eq data (cl-ggplot2::plot-data p)))
    (is (null (cl-ggplot2::plot-mapping p)))))

(test test-apply-layer
  (let* ((p (ggplot nil))
         (l (make-instance 'cl-ggplot2::layer :geom :point :stat :identity)))
    (apply-to-plot l p)
    (is (= 1 (length (cl-ggplot2::plot-layers p))))
    (is (eq l (first (cl-ggplot2::plot-layers p))))))

(test test-threading-operator
  (let* ((p (ggplot nil))
         (l1 (make-instance 'cl-ggplot2::layer :geom :point :stat :identity))
         (l2 (make-instance 'cl-ggplot2::layer :geom :line :stat :identity))
         (result (-+ p l1 l2)))
    (is (eq p result))
    (is (= 2 (length (cl-ggplot2::plot-layers p))))
    (is (eq l1 (first (cl-ggplot2::plot-layers p))))
    (is (eq l2 (second (cl-ggplot2::plot-layers p))))))

(test test-gg-macro
  (let* ((data '((:x . 1)))
         (p (gg (data (aes :x "x"))
              (make-instance 'cl-ggplot2::layer :geom :point :stat :identity))))
    (is (eq data (cl-ggplot2::plot-data p)))
    (is (not (null (cl-ggplot2::plot-mapping p))))
    (is (= 1 (length (cl-ggplot2::plot-layers p))))))
