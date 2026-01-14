(in-package #:cl-ggplot2)

(defmacro -+ (plot &rest items)
  "Thread-like operator for plot composition."
  (let ((p (gensym "PLOT")))
    `(let ((,p ,plot))
       ,@(mapcar (lambda (item) `(apply-to-plot ,item ,p)) items)
       ,p)))

(defmacro gg (spec &rest body)
  "Declarative macro for plot construction."
  (let ((data (if (and (listp spec) (eq (car spec) 'data))
                  (cadr spec)
                  (if (listp spec) (car spec) spec)))
        (mapping (if (and (listp spec) (not (eq (car spec) 'data)))
                     (cadr spec)
                     nil)))
    `(-+ (ggplot ,data ,mapping)
         ,@body)))

(defmacro with-plot ((data &optional mapping) &rest body)
  "Alias for gg."
  `(gg (,data ,mapping) ,@body))
