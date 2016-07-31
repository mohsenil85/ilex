#|
  This file is a part of ilex project.
|#

(in-package :cl-user)
(defpackage ilex-test-asd
  (:use :cl :asdf))
(in-package :ilex-test-asd)

(defsystem ilex-test
  :author ""
  :license ""
  :depends-on (:ilex
               :prove)
  :components ((:module "t"
                :components
                ((:test-file "ilex"))))
  :description "Test system for ilex"

  :defsystem-depends-on (:prove-asdf)
  :perform (test-op :after (op c)
                    (funcall (intern #.(string :run-test-system) :prove-asdf) c)
                    (asdf:clear-system c)))
