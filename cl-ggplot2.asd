(asdf:defsystem #:cl-ggplot2
  :description "Grammar of Graphics for Common Lisp"
  :author "Deepmind"
  :license "MIT"
  :depends-on (#:cl-tibble
               #:cl-vctrs-lite)
  :serial t
  :components ((:module "src"
                :components
                ((:file "package")
                 (:file "core")
                 (:file "aes")
                 (:file "apply")
                 (:file "operator"))))
  :in-order-to ((asdf:test-op (asdf:test-op #:cl-ggplot2/test))))

(asdf:defsystem #:cl-ggplot2/test
  :depends-on (#:cl-ggplot2
               #:fiveam)
  :serial t
  :components ((:module "test"
                :components
                ((:file "package")
                 (:file "smoke-tests"))))
  :perform (asdf:test-op (op c)
                         (uiop:symbol-call :fiveam :run! :cl-ggplot2)))
