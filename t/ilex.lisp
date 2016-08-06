(in-package :cl-user)
(defpackage ilex-test
  (:use :cl
        :ilex
        :prove))
(in-package :ilex-test)

;; NOTE: To run this test file, execute `(asdf:test-system :ilex)' in your Lisp.
;;(setf prove:*default-reporter* :tap)

(plan 6)

;; (defparameter buf 
;;   (make-instance 'ilex::<buffer> 
;;    :contents '("haha" "foo" "lol")
;;    :path #p"./foo.test" ))

;; (ilex::save-buffer buf)

;; (with-open-file (f #p"./foo.test" 
;;                    :direction :input)
;;   (is (read-line f) "haha"))



(let ((buf (ilex::create-buffer "new-buf" :path "")))
  (is (ilex::get-path buf) "")
  (is (ilex::name buf) "new-buf")
  (is (ilex::cursor-x buf) 0))

(is (ilex::insert-after-string "abc" 1 "x") "axbc")
(is (ilex::insert-after-list '('a 'b 'c) 0 'x ) '('a x 'b 'c))


(finalize)
