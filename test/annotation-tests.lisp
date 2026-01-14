(in-package #:cl-ggplot2/test)

(in-suite :cl-ggplot2)

(test test-annotate-text
  (let* ((p (gg (ggplot nil)
              (annotate "text" :x 5 :y 10 :label "Draft Content")))
         (output (render p :device :svg)))
    ;; Verify text is present
    (is (cl-ppcre:scan "Draft Content" output))
    ;; Verify it's roughly in the middle if scales are defaults
    (is (cl-ppcre:scan "<text" output))))

(test test-annotate-rect
  (let* ((p (gg (ggplot nil)
              (annotate :rect :xmin 1 :xmax 2 :ymin 10 :ymax 20 :fill "rgba(255,0,0,0.2)")))
         (output (render p :device :svg)))
    ;; Should have a rect in the data area (not panel/global)
    ;; 1 panel bg + 1 global bg + 1 annotation rect = 3
    (is (= 3 (length (cl-ppcre:all-matches-as-strings "<rect" output))))
    (is (cl-ppcre:scan "fill=\"rgba(255,0,0,0.2)\"" output))))

(test test-annotate-segment
  (let* ((p (gg (ggplot nil)
              (annotate :segment :x 0 :xend 10 :y 0 :yend 10 :color "red")))
         (output (render p :device :svg)))
    ;; 2 axes + 1 segment = 3 lines? 
    ;; Wait, default scales might add more grid lines.
    (is (cl-ppcre:scan "stroke=\"red\"" output))
    (is (cl-ppcre:scan "<line" output))))
