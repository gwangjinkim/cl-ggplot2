(uiop:define-package #:cl-ggplot2
  (:use #:cl)
  (:export
   ;; Core
   #:ggplot
   #:aes
   #:-+
   #:apply-to-plot
   #:gg
   #:with-plot

   ;; Geoms
   #:geom_point
   #:geom_line
   #:geom_bar
   #:geom_histogram

   ;; Stats
   #:stat_identity
   #:stat_count
   #:stat_bin

   ;; Scales
   #:scale-train
   #:scale-map
   #:scale-breaks
   #:scale-channel
   #:scale_x_continuous
   #:scale_y_continuous
   #:scale_x_discrete
   #:scale_y_discrete
   #:scale_color_discrete
   #:scale_color_continuous

   ;; Themes & Labels
   #:theme_minimal
   #:theme_ggplot2_approx
   #:labs

   ;; Output
   #:render
   #:save))
