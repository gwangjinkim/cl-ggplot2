(in-package #:cl-ggplot2)

(defun %aes-slot-name (aes-key)
  (case aes-key
    (:x 'x)
    (:y 'y)
    (:color 'color)
    (:fill 'fill)
    (:size 'size)
    (:shape 'shape)
    (:alpha 'alpha)
    (:group 'group)
    (:linetype 'linetype)
    (:xmin 'xmin)
    (:xmax 'xmax)
    (:ymin 'ymin)
    (:ymax 'ymax)
    (:middle 'middle)
    (:lower 'lower)
    (:upper 'upper)
    (t aes-key)))

(defun %split-data-by-facet (data facet-var)
  "Splits a tibble into a plist of (value . sub-tibble)."
  (if (not facet-var)
      (list :default data)
      (let* ((col-name (if (keywordp facet-var) (string-downcase (string facet-var)) facet-var))
             (vals (cl-tibble:tbl-col data col-name))
             (unique-vals (remove-duplicates (coerce vals 'list) :test #'equal))
             (result nil))
        (dolist (uv unique-vals)
          (let ((indices (loop for i from 0 below (length vals)
                               when (equal (aref vals i) uv)
                               collect i)))
            (setf result (append result (list uv (cl-tibble:slice data :rows indices))))))
        result)))

(defun build-plot (plot width height)
  "Bridges the gap between plot specification and rendering instructions."
  (let* ((data (plot-data plot))
         (layers (plot-layers plot))
         (facet (plot-facet plot))
         (coord (or (plot-coord plot) (coord_cartesian)))
         (margin 50)
         ;; Initialize scales from plot
         (scales (plot-scales plot)))
    
    ;; 1. Facet Resolution
    (let* ((facet-var (when facet (facet-facets facet)))
           (split-data (%split-data-by-facet data facet-var))
           (panel-values (loop for (val tbl) on split-data by #'cddr collect val))
           (n-panels (length panel-values))
           (ncol (or (when facet (facet-ncol facet)) (ceiling (sqrt n-panels)) 1))
           (nrow (ceiling n-panels ncol))
           ;; Panel dimensions
           (panel-width (/ (- width (* 2 margin)) ncol))
           (panel-height (/ (- height (* 2 margin)) nrow))
           (panels nil))

      ;; 2. Stat Computation & Global Scale Training
      ;; Ensure basic scales exist if not already provided
      (dolist (c '(:x :y))
        (unless (gethash c scales)
          (setf (gethash c scales) (make-instance 'scale-continuous :channel c))))

      (loop for p-val in panel-values
            for p-idx from 0
            do (let* ((p-row (floor p-idx ncol))
                      (p-col (mod p-idx ncol))
                      (p-x (+ margin (* p-col panel-width)))
                      (p-y (+ margin (* p-row panel-height)))
                      (p-tibble (getf split-data p-val))
                      (p-layers nil))
                 (dolist (l layers)
                   (let* ((l-data (or (layer-data l) p-tibble))
                          (l-mapping (or (layer-mapping l) (plot-mapping plot)))
                          (l-stat (layer-stat l)))
                     (multiple-value-bind (transformed-data changed-aes)
                         (stat-compute l-stat l-data l-mapping (layer-params l))
                       (let ((final-mapping (make-instance 'mapping)))
                         (dolist (slot '(x y color fill size shape alpha group linetype xmin xmax ymin ymax middle lower upper))
                           (setf (slot-value final-mapping slot) (slot-value l-mapping slot)))
                         (loop for (aes-key col-name) on changed-aes by #'cddr
                               do (setf (slot-value final-mapping (%aes-slot-name aes-key)) col-name))
                         
                         ;; 2b. Position Adjustment
                         (let* ((pos-attr (layer-position l))
                                (pos (cond ((eq pos-attr :identity) (position_identity))
                                           ((eq pos-attr :stack) (position_stack))
                                           ((eq pos-attr :dodge) (position_dodge))
                                           ((eq pos-attr :fill) (position_fill))
                                           ((typep pos-attr 'position-adj) pos-attr)
                                           (t (position_identity))))
                                (pos-data (make-hash-table)))
                           ;; Normalize for position logic
                           (dolist (c '(:x :y :group :color :fill :xmin :xmax :ymin :ymax))
                             (let* ((selector (slot-value final-mapping (%aes-slot-name c)))
                                    (constant (getf (layer-params l) c)))
                               (if constant
                                   (setf (gethash c pos-data) constant)
                                   (when selector
                                     (let ((col-name (if (keywordp selector) (string-downcase (string selector)) selector)))
                                       (setf (gethash c pos-data) (cl-tibble:tbl-col transformed-data col-name)))))))
                           
                           (position-adjust pos pos-data (layer-params l))

                           ;; Global Training
                           (dolist (channel '(:x :y :color :fill :size :alpha :shape :linetype :xmin :xmax :ymin :ymax :middle :lower :upper))
                             (let* ((cs-key (case channel
                                              ((:xmin :xmax) :x)
                                              ((:ymin :ymax :middle :lower :upper) :y)
                                              (t channel)))
                                    (col-selector (slot-value final-mapping (%aes-slot-name channel)))
                                    (constant-override (getf (layer-params l) channel))
                                    (pos-val (gethash channel pos-data)))
                               (let ((values (cond
                                               ((and (member channel '(:x :y))
                                                     (or (gethash :xmin pos-data) (gethash :ymin pos-data)))
                                                nil)
                                               ((and (member channel '(:x :y :xmin :xmax :ymin :ymax)) pos-val)
                                                (if (or (not (typep pos-val 'sequence)) (stringp pos-val))
                                                    (vector pos-val)
                                                    pos-val))
                                               ((and col-selector (not constant-override))
                                                (let ((col-name (if (keywordp col-selector) (string-downcase (string col-selector)) col-selector)))
                                                  (cl-tibble:tbl-col transformed-data col-name)))
                                               (t nil))))
                                 (when (and values (> (length values) 0))
                                   (unless (gethash cs-key scales)
                                     (setf (gethash cs-key scales)
                                           (case cs-key
                                             (:color (make-instance 'scale-color-discrete :channel :color))
                                             (:fill (make-instance 'scale-fill-discrete :channel :fill))
                                             (:size (make-instance 'scale-size-continuous :channel :size))
                                             (:alpha (make-instance 'scale-alpha-continuous :channel :alpha))
                                             (:shape (make-instance 'scale-shape-discrete :channel :shape))
                                             (t (make-instance 'scale-continuous :channel cs-key)))))
                                   (when (member cs-key '(:x :y))
                                     (when (and (not (typep (gethash cs-key scales) 'scale-discrete))
                                                (loop for i from 0 below (min 10 (length values))
                                                      for v = (aref values i)
                                                      thereis (not (or (cl-vctrs-lite:na-p v) (numberp v)))))
                                       (setf (gethash cs-key scales) (make-instance 'scale-discrete :channel cs-key))))
                                   (scale-train (gethash cs-key scales) values)))))
                           
                           (push (list :layer l :data transformed-data :pos-data pos-data :mapping final-mapping) p-layers))))))
                 (push (list :value p-val :x p-x :y p-y :width panel-width :height panel-height :layers (nreverse p-layers)) panels)))

      ;; 3. Final Mapping per Panel
      (let ((built-panels
              (loop for p in (nreverse panels)
                    collect
                    (let* ((p-x (getf p :x))
                           (p-y (getf p :y))
                           (p-w (getf p :width))
                           (p-h (getf p :height))
                           ;; Coordinate-dependent ranges
                           (coord-map (coord-map-scales coord scales p-x p-y p-w p-h))
                           (x-range (getf coord-map :x-range))
                           (y-range (getf coord-map :y-range))
                           (p-layers
                             (loop for pl in (getf p :layers)
                                   collect
                                   (let* ((l (getf pl :layer))
                                          (l-data (getf pl :data))
                                          (l-pos-data (getf pl :pos-data))
                                          (l-mapping (getf pl :mapping))
                                          (mapped-data (make-hash-table)))
                                     (dolist (c '(:x :y :color :fill :size :alpha :shape :linetype :xmin :xmax :ymin :ymax :middle :lower :upper))
                                       (let ((selector (slot-value l-mapping (%aes-slot-name c)))
                                             (constant (getf (layer-params l) c))
                                             (pos-val (gethash c l-pos-data)))
                                         (cond 
                                           ((and (member c '(:x :y :xmin :xmax :ymin :ymax)) pos-val)
                                            (let* ((scale (gethash (case c ((:xmin :xmax) :x)
                                                                           ((:ymin :ymax :middle :lower :upper) :y)
                                                                           (t c)) scales))
                                                   (vals (if (or (not (typep pos-val 'sequence)) (stringp pos-val))
                                                             (vector pos-val)
                                                             pos-val)))
                                              (setf (gethash c mapped-data)
                                                    (case c
                                                      ((:x :xmin :xmax) (scale-map scale vals (first x-range) (second x-range)))
                                                      ((:y :ymin :ymax :middle :lower :upper) (scale-map scale vals (first y-range) (second y-range)))
                                                      (t (scale-map scale vals 0 1))))))
                                           (constant (setf (gethash c mapped-data) constant))
                                           (selector
                                            (let* ((col-name (if (keywordp selector) (string-downcase (string selector)) selector))
                                                   (vals (cl-tibble:tbl-col l-data col-name))
                                                   (scale (gethash (case c ((:xmin :xmax) :x)
                                                                           ((:ymin :ymax :middle :lower :upper) :y)
                                                                           (t c)) scales)))
                                              (setf (gethash c mapped-data)
                                                    (case c
                                                      ((:x :xmin :xmax) (scale-map scale vals (first x-range) (second x-range)))
                                                      ((:y :ymin :ymax :middle :lower :upper) (scale-map scale vals (first y-range) (second y-range)))
                                                      (t (scale-map scale vals 0 1))))))
                                           (t nil))))
                                     ;; Final coordinate transform (e.g. flip)
                                     (list :layer l :data (coord-transform-mapped coord mapped-data))))))
                      (list :value (getf p :value) :x p-x :y p-y :width p-w :height p-h :layers p-layers)))))
        
        (list :panels built-panels :scales scales :ncol ncol :nrow nrow :panel-width panel-width :panel-height panel-height)))))

(defun %draw-labels (plot renderer width height margin)
  (declare (ignore margin))
  (let ((title (plot-title plot))
        (subtitle (plot-subtitle plot))
        (x-lab (plot-x-label plot))
        (y-lab (plot-y-label plot))
        (theme (or (plot-theme plot) (make-instance 'theme))))
    (r-set-style renderer :fill (theme-axis-text-color theme))
    (when title
      (r-text renderer (/ width 2) 20 title :anchor "middle" :font-size 16))
    (when subtitle
      (r-text renderer (/ width 2) 40 subtitle :anchor "middle" :font-size 12))
    (when x-lab
      (r-text renderer (/ width 2) (- height 10) x-lab :anchor "middle" :font-size 12))
    (when y-lab
      (r-set-style renderer :fill (theme-axis-text-color theme))
      (r-text renderer 15 (/ height 2) y-lab :anchor "middle" :font-size 12 :angle -90))))

(defun draw-panel-skeleton (plot renderer p-info theme built-scales)
  "Draws background and grids for a single panel."
  (let* ((p-x (getf p-info :x))
         (p-y (getf p-info :y))
         (p-w (getf p-info :width))
         (p-h (getf p-info :height))
         (p-val (getf p-info :value))
         (coord (or (plot-coord plot) (coord_cartesian)))
         (x-scale (gethash :x built-scales))
         (y-scale (gethash :y built-scales))
         ;; Resolve ranges for labels/grids
         (coord-map (coord-map-scales coord built-scales p-x p-y p-w p-h))
         (x-range (getf coord-map :x-range))
         (y-range (getf coord-map :y-range)))
    ;; Panel background
    (r-set-style renderer :fill (theme-panel-fill theme) :stroke (theme-panel-stroke theme) :stroke-width 1)
    (r-rect renderer p-x p-y p-w p-h)
    
    ;; Strip (Facet Label)
    (when (not (eq p-val :default))
      (r-set-style renderer :fill "#eeeeee" :stroke (theme-panel-stroke theme) :stroke-width 1)
      (r-rect renderer p-x p-y p-w 20)
      (r-set-style renderer :fill (theme-axis-text-color theme))
      (r-text renderer (+ p-x (/ p-w 2)) (+ p-y 15) (format nil "~a" p-val) :anchor "middle" :font-size 10))

    ;; Y-axis breaks & grid
    (when y-scale
      (let ((breaks (scale-breaks y-scale)))
        (dolist (b breaks)
          (let ((y (scale-map y-scale (vector b) (first y-range) (second y-range))))
            (setf y (aref y 0))
            (r-set-style renderer :stroke (theme-grid-color theme) :stroke-width 1)
            ;; If flipped, y-scale values are mapped to horizontal pixels.
            (if (typep coord 'coord-flip)
                (r-line renderer y p-y y (+ p-y p-h))
                (r-line renderer p-x y (+ p-x p-w) y))
            ;; Ticks/Labels
            (unless (typep coord 'coord-flip)
              (when (<= (abs (- p-x 50)) 2)
                (r-set-style renderer :stroke (theme-axis-tick-color theme) :stroke-width 1)
                (r-line renderer (- p-x 5) y p-x y)
                (r-set-style renderer :fill (theme-axis-text-color theme))
                (r-text renderer (- p-x 10) y (format nil "~a" b) :anchor "end" :font-size (theme-axis-text-size theme))))))))

    ;; X-axis breaks & grid
    (when x-scale
      (let ((breaks (scale-breaks x-scale)))
        (dolist (b breaks)
          (let ((x (scale-map x-scale (vector b) (first x-range) (second x-range))))
            (setf x (aref x 0))
            (r-set-style renderer :stroke (theme-grid-color theme) :stroke-width 1)
            ;; If flipped, x-scale values are mapped to vertical pixels.
            (if (typep coord 'coord-flip)
                (r-line renderer p-x x (+ p-x p-w) x)
                (r-line renderer x p-y x (+ p-y p-h)))
            ;; Ticks/Labels
            (unless (typep coord 'coord-flip)
              (r-set-style renderer :stroke (theme-axis-tick-color theme) :stroke-width 1)
              (r-line renderer x (+ p-y p-h) x (+ p-y p-h 5))
              (r-set-style renderer :fill (theme-axis-text-color theme))
              (r-text renderer x (+ p-y p-h 15) (format nil "~a" b) :anchor "middle" :font-size (theme-axis-text-size theme)))))))

    ;; Axes lines
    (r-set-style renderer :stroke (theme-axis-line-color theme) :stroke-width 1)
    (r-line renderer p-x (+ p-y p-h) (+ p-x p-w) (+ p-y p-h)) ; bottom
    (r-line renderer p-x p-y p-x (+ p-y p-h))))

(defun render (plot &key (device :svg) (width 600) (height 400) (dpi 96))
  (declare (ignore dpi))
  (let* ((renderer (ecase device
                     (:svg (make-instance 'svg-renderer))))
         (built (build-plot plot width height))
         (panels (getf built :panels))
         (scales (getf built :scales))
         (theme (or (plot-theme plot) (make-instance 'theme)))
         (margin 50))
    
    (r-begin renderer width height)
    
    ;; Global background
    (r-set-style renderer :fill "white" :stroke "none")
    (r-rect renderer 0 0 width height)
    
    ;; Labels
    (%draw-labels plot renderer width height margin)
    
    ;; Panels
    (dolist (p-info panels)
      (draw-panel-skeleton plot renderer p-info theme scales)
      ;; Render layers for this panel
      (dolist (l-info (getf p-info :layers))
        (let ((geom (layer-geom (getf l-info :layer)))
              (data (getf l-info :data)))
          (geom-draw geom data renderer))))
    
    (r-end renderer)))

(defun save (plot filename &key (width 600) (height 400) (device :svg))
  (let ((output (render plot :device device :width width :height height)))
    (with-open-file (out filename :direction :output :if-exists :supersede :external-format :utf-8)
      (write-string output out))
    filename))
