(in-package #:cl-ggplot2)

(defun render (plot &key (device :svg) (width 600) (height 400) (dpi 96))
  "Render a plot to a string or bytes using the specified device."
  (declare (ignore dpi))
  (let ((renderer (ecase device
                    (:svg (make-instance 'svg-renderer)))))
    (r-begin renderer width height)
    ;; v0.1: Just draw a skeleton for now
    (draw-plot-skeleton plot renderer width height)
    (r-end renderer)))

(defun save (plot path &key (device :svg) (width 600) (height 400) (dpi 96))
  "Render and save a plot to a file."
  (let ((content (render plot :device device :width width :height height :dpi dpi)))
    (with-open-file (out path :direction :output :if-exists :supersede :external-format :utf-8)
      (write-string content out))))

(defun draw-plot-skeleton (plot renderer width height)
  "Internal function to draw axes and panel area."
  (declare (ignore plot))
  ;; Basic margins for v0.1 skeleton
  (let ((margin 50))
    ;; Background panel
    (r-set-style renderer :fill "#f0f0f0" :stroke "#cccccc" :stroke-width 1)
    (r-rect renderer margin margin (- width (* 2 margin)) (- height (* 2 margin)))
    
    ;; Axes placeholders
    (r-set-style renderer :stroke "black" :stroke-width 1)
    ;; X axis
    (r-line renderer margin (- height margin) (- width margin) (- height margin))
    ;; Y axis
    (r-line renderer margin margin margin (- height margin))))
