(in-package #:cl-ggplot2)

(defun build-plot (plot width height)
  "Bridges the gap between plot specification and rendering instructions."
  (let* ((data (plot-data plot))
         (layers (plot-layers plot))
         (margin 50)
         ;; 1. Train scales
         (scales (make-hash-table)))
    
    ;; Initialize default scales if missing
    (dolist (c '(:x :y))
      (setf (gethash c scales) (make-instance 'scale-continuous :channel c)))

    ;; Train across all layers
    (dolist (l layers)
      (let* ((l-data (or (layer-data l) data))
             (l-mapping (or (layer-mapping l) (plot-mapping plot))))
        (dolist (channel '(:x :y))
          (let* ((col-selector (ecase channel
                                 (:x (aes-x l-mapping))
                                 (:y (aes-y l-mapping))))
                 (col-name (if (keywordp col-selector) 
                               (string-downcase (string col-selector))
                               col-selector))
                 (values (cl-tibble:tbl-col l-data col-name)))
            (scale-train (gethash channel scales) values)))))

    ;; 2. Map data to coordinates per layer
    (let ((built-layers
            (loop for l in layers
                  collect
                  (let* ((l-data (or (layer-data l) data))
                         (l-mapping (or (layer-mapping l) (plot-mapping plot)))
                         (mapped-data (make-hash-table)))
                    ;; For x and y, map to screen positions
                    (dolist (c '(:x :y))
                      (let* ((selector (ecase c
                                         (:x (aes-x l-mapping))
                                         (:y (aes-y l-mapping))))
                             (col-name (if (keywordp selector)
                                           (string-downcase (string selector))
                                           selector))
                             (vals (cl-tibble:tbl-col l-data col-name))
                             (scale (gethash c scales)))
                        (setf (gethash c mapped-data)
                              (if (eq c :x)
                                  (scale-map scale vals margin (- width margin))
                                  ;; SVG Y is top-down, so invert mapping
                                  (scale-map scale vals (- height margin) margin)))))
                    
                    ;; Milestone 5: Sort by X for geom_line
                    (when (typep (layer-geom l) 'geom-line)
                      (let* ((x-vals (gethash :x mapped-data))
                             (y-vals (gethash :y mapped-data))
                             (indices (cl-vctrs-lite:with-na-handling ; just in case
                                        (let ((idx (loop for i from 0 below (length x-vals) collect i)))
                                          (sort idx #'< :key (lambda (i) (aref x-vals i))))))
                             (new-x (make-array (length x-vals) :element-type (array-element-type x-vals)))
                             (new-y (make-array (length y-vals) :element-type (array-element-type y-vals))))
                        (loop for i from 0 for original-idx in indices
                              do (setf (aref new-x i) (aref x-vals original-idx)
                                       (aref new-y i) (aref y-vals original-idx)))
                        (setf (gethash :x mapped-data) new-x
                              (gethash :y mapped-data) new-y)))

                    ;; For others (color, etc.), just pick params or defaults for now
                    (dolist (c '(:color :size :alpha))
                      (setf (gethash c mapped-data) (getf (layer-params l) c)))
                    
                    (list :layer l :data mapped-data)))))
      
      (list :layers built-layers :scales scales))))

;; Redefine render-api's render to use build-plot
(defun render (plot &key (device :svg) (width 600) (height 400) (dpi 96))
  (declare (ignore dpi))
  (let ((renderer (ecase device
                    (:svg (make-instance 'svg-renderer))))
        (built (build-plot plot width height)))
    (r-begin renderer width height)
    (draw-plot-skeleton plot renderer width height)
    
    ;; Draw layers
    (dolist (bl (getf built :layers))
      (let ((layer (getf bl :layer))
            (data (getf bl :data)))
        (geom-draw (layer-geom layer) data renderer)))
    
    (r-end renderer)))
