(in-package #:cl-ggplot2)

(defun build-plot (plot width height)
  "Bridges the gap between plot specification and rendering instructions."
  (let* ((data (plot-data plot))
         (layers (plot-layers plot))
         (margin 50)
         (scales (make-hash-table)))
    
    ;; 1. Stat Computation & Initial Mapping Resolution
    (let ((processed-layers
            (loop for l in layers
                  collect
                  (let* ((l-data (or (layer-data l) data))
                         (l-mapping (or (layer-mapping l) (plot-mapping plot)))
                         (l-stat (layer-stat l)))
                    (multiple-value-bind (transformed-data transformed-mapping)
                        (stat-compute l-stat l-data l-mapping (layer-params l))
                      (list :layer l :data transformed-data :mapping transformed-mapping))))))

      ;; 2. Initialize and Train scales
      (dolist (c '(:x :y))
        (setf (gethash c scales) (make-instance 'scale-continuous :channel c)))

      (dolist (pl processed-layers)
        (let ((l-data (getf pl :data))
              (l-mapping (getf pl :mapping)))
          (dolist (channel '(:x :y))
            (let ((col-selector (ecase channel
                                  (:x (aes-x l-mapping))
                                  (:y (aes-y l-mapping)))))
              (when col-selector
                (let* ((col-name (if (keywordp col-selector) 
                                     (string-downcase (string col-selector))
                                     col-selector))
                       (values (cl-tibble:tbl-col l-data col-name)))
                  ;; Upgrade scale to discrete if data is non-numeric
                  (when (and (not (typep (gethash channel scales) 'scale-discrete))
                             (loop for i from 0 below (min 10 (length values))
                                   for v = (aref values i)
                                   thereis (not (or (cl-vctrs-lite:na-p v) (numberp v)))))
                    (setf (gethash channel scales) (make-instance 'scale-discrete :channel channel)))
                  
                  (scale-train (gethash channel scales) values)))))))

      ;; 3. Map data to coordinates
      (let ((built-layers
              (loop for pl in processed-layers
                    collect
                    (let* ((l (getf pl :layer))
                           (l-data (getf pl :data))
                           (l-mapping (getf pl :mapping))
                           (mapped-data (make-hash-table)))
                      (dolist (c '(:x :y))
                        (let ((selector (ecase c
                                          (:x (aes-x l-mapping))
                                          (:y (aes-y l-mapping)))))
                          (if selector
                              (let* ((col-name (if (keywordp selector)
                                                   (string-downcase (string selector))
                                                   selector))
                                     (vals (cl-tibble:tbl-col l-data col-name))
                                     (scale (gethash c scales)))
                                (setf (gethash c mapped-data)
                                      (if (eq c :x)
                                          (scale-map scale vals margin (- width margin))
                                          (scale-map scale vals (- height margin) margin))))
                              ;; Default mapping if not provided (e.g. y for some geoms)
                              ;; But for now just skip if no selector
                              nil)))
                      
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

                      (dolist (c '(:color :fill :size :alpha :width))
                        (setf (gethash c mapped-data) (getf (layer-params l) c)))
                      
                      (list :layer l :data mapped-data)))))
        
        (list :layers built-layers :scales scales)))))

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
