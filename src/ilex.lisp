(in-package :cl-user)
(defpackage ilex
  (:use :cl
        :cl-charms
        :trivial-types
        :swank)
  (:import-from :uiop/utility :strcat)
  (:import-from :uiop/filesystem :probe-file*)
  (:import-from :uiop/stream 
                :read-file-lines
                :with-safe-io-syntax)
  (:export #:main))
(in-package :ilex)
(declaim (optimize (debug 3)))

;;; here we'd like to make an <editor> object, and have globals like buffer-list
;;; be a part of it
(defparameter *buffer-list* nil "A list of all available buffers")

(defclass <buffer> ()
  ((contents 
    :documentation "a list of strings, one for each line of a file"
    :type (proper-list string)
    :initarg :contents
    :accessor contents) 
   (path
    :type pathname-designator
    :initarg :path
    :reader get-path)
   (cursor-x
    :type number
    :initarg :x
    :initform 0
    :accessor cursor-x)
   (cursor-y
    :type number
    :initarg :y
    :initform 0
    :accessor cursor-y)))

(defmethod save-buffer ((buffer <buffer>))
  "write buffer to the filename specifed in PATH"
  (with-safe-io-syntax () 
    (with-open-file  (file (get-path buffer)
                           :direction :output
                           :if-exists :overwrite
                           :if-does-not-exist :create)
      (dolist (line (contents buffer))
        (write-line line file )))))

(defun create-buffer (path)
  "given a path, return a buffer with the contents at that path,
or initalize a buffer at that path, then push the buffer into the global buffer list"
  (with-safe-io-syntax ()
    (let* ((existing (uiop/filesystem:probe-file* path :truename t))
           (contents (if existing (uiop/stream:read-file-lines path) 'nil))
           (buffer (make-instance '<buffer>
                                  :path path
                                  :contents contents)))
      (push buffer *buffer-list*)
      buffer))) 


(defmethod render-buffer ((buffer <buffer>))
  (charms:refresh-window (charms:standard-window))
  (when (contents buffer)
    (loop for line in (contents buffer)
       with i = 0 do
         (charms:write-string-at-point (charms:standard-window) line 0 i )
         (incf i))))

(defun insert-after-string (string index elt)
  "insert elt into string after index"
  (let ((head (subseq string 0 index))
        (rest (subseq string (1+ index) (length string))))
    (uiop/utility:strcat head elt rest)))

(defun insert-after-list (lst index newelt)
  "insert newelt into list after index"
  (push newelt (cdr (nthcdr index lst))) 
  lst)


(defmethod replace-line ((buffer <buffer>) idx string)
  (setf (nth idx (contents buffer)) string))

(defparameter buf (make-instance '<buffer> 
                                 :y 1
                                 :x 0
                                 :contents '("1" "abcdefg" "3")))
(insert-char "x" buf)


(defmethod insert-char (char (buffer <buffer>))
  "persist a char entry to a buffer (as opposed to writing that buffer to a file).
returns the buffer"
  (let* ((y (cursor-y buffer))
         (contents (contents buffer))
         (line-data (nth y contents))
         (new-data (insert-after-string line-data (cursor-x buffer) char)))
   (replace-line buffer y new-data) 
    buffer))



(defun render-char-at-cursor (c buf)
  "render the char in ncurses"
  (charms:write-char-at-point 
   (charms:standard-window) 
   c 
   (cursor-x buf) 
   (cursor-y buf)))


(defun handle-input (c buf)
  (case c
    ((nil) nil)
    ((#\k) (decf (cursor-y buf)))
    ((#\h) (decf (cursor-x buf)))
    ((#\j) (incf (cursor-y buf)))
    ((#\l) (incf (cursor-x buf)))
    ((#\s ) (save-buffer buf))
    ((#\q #\Q) (sb-ext:exit))
    (t (render-char-at-cursor c buf) )))


(defun input-loop ()
  (loop
     with buf = (create-buffer "my buf")
     for c = (charms:get-char (charms:standard-window) :ignore-error t)
     do
       (charms:move-cursor (charms:standard-window)
                           (cursor-x buf)
                           (cursor-x buf))
       (render-buffer buf)
       (handle-input c buf)))

(defun main (args)
  "top level entry"
  (when (second args)
    (create-buffer (second args)))
  (charms:with-curses ()
    (charms:disable-echoing)
    (charms:enable-raw-input :interpret-control-characters t)
    (charms:enable-non-blocking-mode (charms:standard-window))
    (input-loop)

    ))


(defun swank-init ()
  (swank:set-package 'ilex)
  (swank:create-server :port 9000 :style :spawn :dont-close t))

(defparameter listening nil )
(defparameter connected nil)

(defun on-client-connect (conn)
  (declare (ignore conn))
  (charms:clear-window (charms:standard-window) :force-repaint t)
  (setf connected t))

(defun swank-listen ()
  (unless listening
    (push 'on-client-connect
          swank::*new-connection-hook*)
    (swank-init)
    (setf listening t)))


(defun swank-kill ()
  (when listening
    (swank:stop-server 9000 )
    (setf listening nil)
    (setf connected nil)))

(defun is-swank-running ()
  listening)
(defun is-swank-connected ()
  connected)
