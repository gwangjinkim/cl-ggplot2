(in-package #:cl-ggplot2)

(defun build-plot (plot width height)
  "Bridges the gap between plot specification and rendering instructions."
  (let* ((data (plot-data plot))
         (layers (plot-layers plot))
         (margin 50)
         (scales (make-hash-table)))
    
    ;; 1. Stat Computation & Final Mapping Resolution
    (let ((processed-layers
            (loop for l in layers
                  collect
                  (let* ((l-data (or (layer-data l) data))
                         (l-mapping (or (layer-mapping l) (plot-mapping plot)))
                         (l-stat (layer-stat l)))
                    (multiple-value-bind (transformed-data changed-aes)
                        (stat-compute l-stat l-data l-mapping (layer-params l))
                      ;; Merge changed aesthetics into mapping
                      (let ((final-mapping (make-instance 'mapping)))
                        ;; Copy from l-mapping
                        (dolist (slot '(x y color fill size shape alpha group linetype))
                          (setf (slot-value final-mapping slot) (slot-value l-mapping slot)))
                        ;; Apply changes from stat
                        (loop for (aes-key col-name) on changed-aes by #'cddr
                              do (setf (slot-value final-mapping (case aes-key (:x 'x) (:y 'y) (t aes-key))) col-name))
                        (list :layer l :data transformed-data :mapping final-mapping)))))))

      ;; 2. Initialize and Train scales
      (dolist (c '(:x :y))
        (setf (gethash c scales) (make-instance 'scale-continuous :channel c)))

      (dolist (pl processed-layers)
        (let ((l-data (getf pl :data))
              (l-mapping (getf pl :mapping))
              (l (getf pl :layer)))
          (dolist (channel '(:x :y :color :fill :size :alpha :shape :linetype))
            (let ((col-selector (slot-value l-mapping (case channel
                                                       (:x 'x) (:y 'y) (:color 'color) (:fill 'fill)
                                                       (:size 'size) (:alpha 'alpha) (:shape 'shape) (:linetype 'linetype))))
                  (constant-override (getf (layer-params l) channel)))
              ;; Only train scale if there is a mapping AND no constant override in this layer
              (when (and col-selector (not constant-override))
                (let* ((col-name (if (keywordp col-selector) 
                                     (string-downcase (string col-selector))
                                     col-selector))
                       (values (cl-tibble:tbl-col l-data col-name)))
                  
                  ;; Auto-create scale if missing
                  (unless (gethash channel scales)
                    (setf (gethash channel scales)
                          (case channel
                            (:color (make-instance 'scale-color-discrete :channel :color))
                            (:fill (make-instance 'scale-fill-discrete :channel :fill))
                            (t (make-instance 'scale-continuous :channel channel)))))

                  ;; Upgrade scale to discrete if data is non-numeric (for X and Y)
                  (when (member channel '(:x :y))
                    (when (and (not (typep (gethash channel scales) 'scale-discrete))
                               (loop for i from 0 below (min 10 (length values))
                                     for v = (aref values i)
                                     thereis (not (or (cl-vctrs-lite:na-p v) (numberp v)))))
                      (setf (gethash channel scales) (make-instance 'scale-discrete :channel channel))))
                  
                  (scale-train (gethash channel scales) values)))))))

      ;; 3. Map data to coordinates
      (let ((built-layers
              (loop for pl in processed-layers
                    collect
                    (let* ((l (getf pl :layer))
                           (l-data (getf pl :data))
                           (l-mapping (getf pl :mapping))
                           (mapped-data (make-hash-table)))
                      
                      ;; Resolve all aesthetics
                      (dolist (c '(:x :y :color :fill :size :alpha :shape :linetype))
                        (let ((selector (slot-value l-mapping (case c
                                                                (:x 'x) (:y 'y) (:color 'color) (:fill 'fill)
                                                                (:size 'size) (:alpha 'alpha) (:shape 'shape) (:linetype 'linetype))))
                              (constant (getf (layer-params l) c)))
                          (cond 
                            ;; 1. Constant override in layer
                            (constant
                             (setf (gethash c mapped-data) constant))
                            ;; 2. Mapping exists
                            (selector
                             (let* ((col-name (if (keywordp selector)
                                                  (string-downcase (string selector))
                                                  selector))
                                    (vals (cl-tibble:tbl-col l-data col-name))
                                    (scale (gethash c scales)))
                               (setf (gethash c mapped-data)
                                     (case c
                                       (:x (scale-map scale vals margin (- width margin)))
                                       (:y (scale-map scale vals (- height margin) margin))
                                       (t (scale-map scale vals 0 1))))))
                            ;; 3. No mapping, no constant
                            (t nil))))
                      
                      ;; Sort if geom-line
                      (when (typep (layer-geom l) 'geom-line)
                        (let* ((x-vals (gethash :x mapped-data))
                               (y-vals (gethash :y mapped-data))
                               (indices (let ((idx (loop for i from 0 below (length x-vals) collect i)))
                                          (sort idx (lambda (a b)
                                                      (let ((va (aref x-vals a))
                                                            (vb (aref x-vals b)))
                                                        (cond ((cl-vctrs-lite:na-p va) nil)
                                                              ((cl-vctrs-lite:na-p vb) t)
                                                              (t (< va vb))))))))
                               (new-x (make-array (length x-vals) :element-type (array-element-type x-vals)))
                               (new-y (make-array (length y-vals) :element-type (array-element-type y-vals))))
                          (loop for i from 0 for original-idx in indices
                                do (setf (aref new-x i) (aref x-vals original-idx)
                                         (aref new-y i) (aref y-vals original-idx)))
                          (setf (gethash :x mapped-data) new-x
                                (gethash :y mapped-data) new-y)))
                      
                      (list :layer l :data mapped-data)))))
        
        (list :layers built-layers :scales scales)))))

(defun %draw-labels (plot renderer width height margin)
  (let ((title (plot-title plot))
        (subtitle (plot-subtitle plot))
        (x-lab (or (plot-x-label plot) 
                   (let ((m (plot-mapping plot)))
                     (when m
                       (let ((sel (aes-x m)))
                         (if (keywordp sel) (string-capitalize (string-downcase (string sel))) sel))))))
        (y-lab (or (plot-y-label plot)
                   (let ((m (plot-mapping plot)))
                     (when m
                       (let ((sel (aes-y m)))
                         (if (keywordp sel) (string-capitalize (string-downcase (string sel))) sel)))))))
    
    (r-set-style renderer :fill "black")
    ;; Title
    (when title
      (r-text renderer (/ width 2) (/ margin 2) title :anchor "middle" :font-size 18))
    ;; Subtitle
    (when subtitle
      (r-text renderer (/ width 2) (+ (/ margin 2) 20) subtitle :anchor "middle" :font-size 14))
    ;; X-axis Label
    (when x-lab
      (r-text renderer (/ width 2) (- height (/ margin 4)) (format nil "~a" x-lab) :anchor "middle" :font-size 12))
    ;; Y-axis Label
    (when y-lab
      (r-text renderer (/ margin 4) (/ height 2) (format nil "~a" y-lab) :anchor "middle" :angle -90 :font-size 12))))

(defun draw-plot-skeleton (plot renderer width height)
  "Internal function to draw axes and panel area."
  (let* ((margin 50)
         (theme (or (plot-theme plot) (make-instance 'theme))))
    ;; Background panel
    (r-set-style renderer :fill (theme-panel-fill theme) :stroke (theme-panel-stroke theme) :stroke-width 1)
    (r-rect renderer margin margin (- width (* 2 margin)) (- height (* 2 margin)))
    
    ;; Gridlines (horizontal)
    (r-set-style renderer :stroke (theme-grid-color theme) :stroke-width 1)
    (loop for i from 1 to 3
          for y = (+ margin (* i (/ (- height (* 2 margin)) 4)))
          do (r-line renderer margin y (- width margin) y))

    ;; Axes placeholders
    (r-set-style renderer :stroke (theme-axis-line-color theme) :stroke-width 1)
    ;; X axis
    (r-line renderer margin (- height margin) (- width margin) (- height margin))
    ;; Y axis
    (r-line renderer margin margin margin (- height margin))
    
    ;; Labels
    (%draw-labels plot renderer width height margin)))

;; Redefine render
(defun render (plot &key (device :svg) (width 600) (height 400) (dpi 96))
  (declare (ignore dpi))
  (let ((renderer (ecase device
                    (:svg (make-instance 'svg-renderer))))
        (built (build-plot plot width height)))
    (r-begin renderer width height)
    (draw-plot-skeleton plot renderer width height)
    (dolist (bl (getf built :layers))
      (let ((layer (getf bl :layer))
            (data (getf bl :data)))
        (geom-draw (layer-geom layer) data renderer)))
    (r-end renderer)))
