(in-package #:cl-ggplot2)

(defmacro -+ (plot &rest items)
  "Thread-like operator for plot composition."
  (let ((p (gensym "PLOT")))
    `(let ((,p ,plot))
       ,@(mapcar (lambda (item) `(apply-to-plot ,item ,p)) items)
       ,p)))

(defmacro gg (spec &rest body)
  "Declarative macro for plot construction."
  (let ((data nil)
        (mapping nil))
    (cond
      ((and (listp spec) 
            (symbolp (car spec)) 
            (string-equal (symbol-name (car spec)) "DATA"))
       (setf data (cadr spec)))
      ((and (listp spec) (<= (length spec) 2))
       (setf data (car spec)
             mapping (cadr spec)))
      (t (setf data spec)))
    `(-+ (ggplot ,data ,mapping)
         ,@body)))

(defmacro with-plot ((data &optional mapping) &rest body)
  "Alias for gg."
  `(gg (,data ,mapping) ,@body))
