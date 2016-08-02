(in-package :cl-user)
(defpackage ilex
  (:use :cl
        :charms
        :trivial-types
        :uiop/stream
        :uiop/filesystem
        :swank)
  (:export #:main))
(in-package :ilex)
(declaim (optimize (debug 3)))

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
    :initarg :cursor-x
    :accessor cursor-x)
   (cursor-y
    :type number
    :initarg :cursor-y
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
 and push the buffer into the global buffer list"
  (with-safe-io-syntax ()
    (let* ((contents (uiop/stream:read-file-lines path))
           (buffer (make-instance '<buffer>
                                  :path path
                                  :contents contents)))
      (push buffer *buffer-list*)
      buffer))) 

(defun initialize-buffer (path)
  "initalize an empty buffer at path"
  (with-safe-io-syntax ()
    (let ((buffer (make-instance '<buffer> :path path)))
      (push buffer *buffer-list*)
      buffer))) 

(let ((existing (uiop/filesystem:probe-file* path :truename t)))
  (if existing 
      (create-buffer existing)
      (initialize-buffer existing)
 ))

(defmethod render-buffer ((buffer <buffer>))
  (charms:refresh-window (charms:standard-window))
  (when (contents buffer)
    (loop for line in (contents buffer)
       with i = 0 do
         (charms:write-string-at-point (charms:standard-window) line 0 i )
         (incf i))))


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
