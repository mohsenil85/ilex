(in-package :cl-user)
(defpackage ilex-test
  (:use :cl
        :ilex
        :prove))
(in-package :ilex-test)

;; NOTE: To run this test file, execute `(asdf:test-system :ilex)' in your Lisp.

(plan 1)

(defparameter buf 
  (ilex::make-buffer 
   :lines '("haha" "foo" "lol")
   :file-name #p"./foo.test" ))

(ilex::save-buffer buf)

(with-open-file (f #p"./foo.test" 
                   :direction :input)
  (is (read-line f) "haha"))

(finalize)
