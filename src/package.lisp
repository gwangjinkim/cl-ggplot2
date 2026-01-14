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
   #:geom_path
   #:geom_line
   #:geom_bar
   #:geom_col
   #:geom_tile
   #:geom_histogram
   #:geom_boxplot
   #:geom_smooth

   ;; Stats
   #:stat_identity
   #:stat_count
   #:stat_bin
   #:stat_boxplot
   #:stat_smooth

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
   #:scale_fill_discrete
   #:scale_color_continuous
   #:scale_size_continuous
   #:scale_alpha_continuous
   #:scale_shape_discrete
   #:scale_color_brewer
   #:scale_fill_brewer
   #:scale_color_manual
   #:scale_fill_manual

   ;; Positions
   #:position_identity
   #:position_stack
   #:position_dodge
   #:position_fill

   ;; Coordinates
   #:coord_cartesian
   #:coord_flip
   #:coord_fixed

   ;; Themes & Labels
   #:theme_minimal
   #:theme_ggplot2_approx
   #:labs
   #:facet_wrap

   ;; Output
   #:render
   #:save
   #:build-plot))
