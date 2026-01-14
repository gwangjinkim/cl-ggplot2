(in-package #:cl-ggplot2/test)

(in-suite :cl-ggplot2)

(test test-scale-discrete-training
  (let ((s (make-instance 'cl-ggplot2::scale-discrete :channel :x)))
    (cl-ggplot2:scale-train s #("A" "B" "A" "C"))
    (is (equal '("A" "B" "C") (cl-ggplot2::scale-domain s)))))

(test test-scale-discrete-mapping
  (let ((s (make-instance 'cl-ggplot2::scale-discrete :channel :x)))
    (cl-ggplot2:scale-train s #("A" "B" "C"))
    (let ((mapped (cl-ggplot2:scale-map s #("A" "B" "C") 0 100)))
      ;; 3 categories, mapped to 16.6, 50, 83.3 (with padding)
      (is (< (abs (- (aref mapped 0) 16.666666d0)) 0.01))
      (is (< (abs (- (aref mapped 1) 50.0d0)) 0.01))
      (is (< (abs (- (aref mapped 2) 83.333333d0)) 0.01)))))

(test test-scale-discrete-breaks
  (let ((s (make-instance 'cl-ggplot2::scale-discrete :channel :x)))
    (cl-ggplot2:scale-train s #("A" "B"))
    (let ((breaks (cl-ggplot2:scale-breaks s)))
      (is (= 2 (length breaks)))
      (is (equal "A" (first breaks))))))
