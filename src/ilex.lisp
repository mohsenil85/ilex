(in-package :cl-user)
(defpackage ilex
  (:use :cl))
(in-package :ilex)


(defstruct buffer
  lines cursor-x cursor-y file-name)

(defun save-buffer (buffer)
  "destructivly save buffer to file-name"
  (with-open-file (file (buffer-file-name buffer)
                        :direction :output
                        :if-exists :overwrite
                        :if-does-not-exist :create)
                  (loop :for line :in (buffer-lines buffer) 
                     :do
                     (write-line line file ))))



