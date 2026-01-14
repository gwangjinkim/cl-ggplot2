(in-package #:cl-ggplot2/test)

(in-suite :cl-ggplot2)

(test test-scale-continuous-training
  (let ((s (make-instance 'cl-ggplot2::scale-continuous :channel :x)))
    (cl-ggplot2:scale-train s #(10 20 30))
    (is (equalp '(10.0d0 30.0d0) (cl-ggplot2::scale-domain s)))
    (cl-ggplot2:scale-train s #(5 35))
    (is (equalp '(5.0d0 35.0d0) (cl-ggplot2::scale-domain s)))))

(test test-scale-continuous-mapping
  (let ((s (make-instance 'cl-ggplot2::scale-continuous :channel :x)))
    (cl-ggplot2:scale-train s #(0 100))
    (let ((mapped (cl-ggplot2:scale-map s #(0 50 100) 0 600)))
      (is (equalp #(0.0d0 300.0d0 600.0d0) mapped)))))

(test test-scale-continuous-na-mapping
  (let ((s (make-instance 'cl-ggplot2::scale-continuous :channel :x)))
    (cl-ggplot2:scale-train s #(0 100))
    (let ((mapped (cl-ggplot2:scale-map s (vector 0 cl-vctrs-lite:*na* 100) 0 600)))
      (is (= 0.0d0 (aref mapped 0)))
      (is (cl-vctrs-lite:na-p (aref mapped 1)))
      (is (= 600.0d0 (aref mapped 2))))))

(test test-scale-breaks
  (let ((s (make-instance 'cl-ggplot2::scale-continuous :channel :x)))
    (cl-ggplot2:scale-train s #(0 10))
    (let ((breaks (cl-ggplot2:scale-breaks s)))
      (is (= 6 (length breaks)))
      (is (= 0.0 (first breaks))))))
