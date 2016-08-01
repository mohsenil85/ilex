#|
  This file is a part of ilex project.
|#

(in-package :cl-user)
(defpackage ilex-asd
  (:use :cl :asdf))
(in-package :ilex-asd)

(defsystem ilex
  :version "0.1"
  :author "mohsenil85@gmail.com"
  :license ""
  :depends-on (:cl-charms)
  :components ((:module "src"
                :components
                ((:file "ilex"))))
  :description ""
  :long-description
  #.(with-open-file (stream (merge-pathnames
                             #p"README.markdown"
                             (or *load-pathname* *compile-file-pathname*))
                            :if-does-not-exist nil
                            :direction :input)
      (when stream
        (let ((seq (make-array (file-length stream)
                               :element-type 'character
                               :fill-pointer t)))
          (setf (fill-pointer seq) (read-sequence seq stream))
          seq)))
  :in-order-to ((test-op (test-op ilex-test))))
