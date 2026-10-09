(in-package #:cl-ggplot2)

(defmacro -+ (plot &rest items)
  "Thread-like operator for plot composition."
  (let ((p (gensym "PLOT")))
    `(let ((,p ,plot))
       ,@(mapcar (lambda (item) `(apply-to-plot ,item ,p)) items)
       ,p)))

(defun %aes-form-p (form)
  "True for a literal (aes ...) form, in any package."
  (and (consp form) (symbolp (car form)) (string-equal (symbol-name (car form)) "AES")))

(defmacro gg (spec &rest body)
  "Declarative macro for plot construction.
SPEC is one of:
  (data EXPR)        EXPR evaluates to the data; no global mapping.
  (EXPR (aes ...))   R style: data and global mapping. This also covers a
                     variable literally named DATA: (data (aes ...)).
  (EXPR MAPPING)     data and a mapping expression.
  EXPR               a symbol naming the data."
  (let ((data nil)
        (mapping nil))
    (cond
      ;; (EXPR (aes ...)) -- checked first so that a data variable called
      ;; DATA followed by an aes form is not mistaken for (data EXPR).
      ((and (consp spec) (= (length spec) 2) (%aes-form-p (second spec)))
       (setf data (first spec)
             mapping (second spec)))
      ((and (consp spec)
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
