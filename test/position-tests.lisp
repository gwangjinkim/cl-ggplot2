(in-package #:cl-ggplot2/test)

(in-suite :cl-ggplot2)

(test test-position-dodge
  (let* ((data (cl-tibble:tibble :x #(1 1 2 2)
                                 :y #(10 20 5 15)
                                 :g #("G1" "G2" "G1" "G2")))
         (p (gg (data (aes :x :x :y :y :fill :g))
              (geom_col :position :dodge)))
         (output (render p :device :svg)))
    ;; Should have 4 bars + 1 global bg + 1 panel bg = 6 rects
    (is (= 6 (length (cl-ppcre:all-matches-as-strings "<rect" output))))
    ;; Verify that we have two different X positions for each nominal X
    (let ((x-coords (mapcar (lambda (s) (cl-ppcre:register-groups-bind (x) ("x=\"([^\"]+)\"" s) x))
                            (cl-ppcre:all-matches-as-strings "<rect [^>]*x=\"[^\"]+\"[^>]*width=\"[^\"]+\"" output))))
      ;; 4 bars should have some distinct X values
      (is (>= (length (remove-duplicates x-coords :test #'string=)) 4)))))

(test test-position-fill
  (let* ((data (cl-tibble:tibble :x #(1 1)
                                 :y #(10 30)
                                 :g #("G1" "G2")))
         (p (gg (data (aes :x :x :y :y :fill :g))
              (geom_col :position :fill)))
         (output (render p :device :svg)))
    ;; Height for 30/40 (0.75) segment should be 3/4 of the total panel height.
    ;; Panel height is 300 (400 - 2*50). 0.75 * 300 = 225.
    (is (cl-ppcre:scan "height=\"225" output))))

(test test-geom-bar-stat-count-new
  (let* ((data (cl-tibble:tibble :x #("A" "A" "B" "A" "C")))
         (p (gg (data (aes :x :x))
              (geom_bar)))
         (output (render p :device :svg)))
    ;; Verify we have 3 bars.
    (is (= 5 (length (cl-ppcre:all-matches-as-strings "<rect" output))))
    ;; A has count 3, B/C have count 1.
    ;; They should have different heights.
    (let ((heights (mapcar (lambda (s) (cl-ppcre:register-groups-bind (h) ("height=\"([^\"]+)\"" s) h))
                           (cl-ppcre:all-matches-as-strings "<rect [^>]*height=\"[^\"]+\"" output))))
       (is (>= (length (remove-duplicates heights :test #'string=)) 2)))))
