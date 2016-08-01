(in-package :cl-user)
(defpackage ilex
  (:use :cl
        :charms)
  (:export #:main))
(in-package :ilex)


(defparameter *buffer-list* nil)
(defstruct buffer
  lines cursor-x cursor-y file-name)

(defparameter buf 
  (ilex::make-buffer 
   :lines '("haha" "foo" "lol")
   :file-name #p"./foo.test" ))

(defun save-buffer (buffer)
  "destructivly save buffer to file-name"
  (with-open-file (file (buffer-file-name buffer)
                        :direction :output
                        :if-exists :overwrite
                        :if-does-not-exist :create)
    (loop :for line :in (buffer-lines buffer) 
       :do
       (write-line line file ))))

(defun create-buffer (name buffer-list)
  "initialize a new buffer, name it, and push it into buffer-list
returns buffer-list "
  (pushnew  
   (make-buffer 
    :cursor-x 0 
    :cursor-y 0 
    :file-name name)
   buffer-list)
  buffer-list) 


(defun render-buffer (buffer)
  (charms:refresh-window charms:*standard-window*)
  (loop for line in (buffer-lines buffer)
     with i = 0 do
       (charms:write-string-at-point *standard-window* line 0 i )
       (incf i)))

(create-buffer "my-buf" *buffer-list*)


(defun input-loop ()
  (loop
     with buf = (car (create-buffer "my buf" *buffer-list*))
     for c = (charms:get-char *standard-window* :ignore-error t)
     do
       (charms:move-cursor *standard-window*
                           (buffer-cursor-x buf)
                           (buffer-cursor-x buf))
       (render-buffer buf)
       (handle-input c buf)))


(defun handle-input (c buf)
  (case c
    ((nil) nil)
    ((#\k) (decf (buffer-cursor-y buf)))
    ((#\h) (decf (buffer-cursor-x buf)))
    ((#\j) (incf (buffer-cursor-y buf)))
    ((#\l) (incf (buffer-cursor-x buf)))
    ((#\s ) (save-buffer buf))
    ((#\q #\Q) (sb-ext:exit))
    (t (charms:write-char-at-point 
        *standard-window* 
        c 
        (buffer-cursor-x buf) 
        (buffer-cursor-y buf)))))

(defun main (args)
  (declare (ignore args ))
  "Start the timer program."
  (charms:with-curses ()
    (charms:disable-echoing)
    (charms:enable-raw-input :interpret-control-characters t)
    (charms:enable-non-blocking-mode charms:*standard-window*)
    (input-loop)

    ))


