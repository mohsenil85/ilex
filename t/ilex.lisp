(in-package :cl-user)
(defpackage ilex-test
  (:use :cl
        :ilex
        :prove))
(in-package :ilex-test)

;; NOTE: To run this test file, execute `(asdf:test-system :ilex)' in your Lisp.

(plan 4)

(defparameter buf 
  (ilex::make-buffer 
   :lines '("haha" "foo" "lol")
   :file-name #p"./foo.test" ))

(ilex::save-buffer buf)

(with-open-file (f #p"./foo.test" 
                   :direction :input)
  (is (read-line f) "haha"))



(let* ((buffer-list (ilex::create-buffer "new-buf" *test-buffers-list*))
       (buf (car buffer-list )))
  (isnt nil buffer-list)
  (is (ilex::buffer-file-name buf) "new-buf")
  (is (ilex::buffer-cursor-x buf) 0))

(finalize)
