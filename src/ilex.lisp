(in-package :cl-user)
(defpackage ilex
  (:use :cl
        :cl-charms
        :trivial-types
        :cl-strings
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
;;;; would also be cool to have *editor* close over some state
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

(defmethod nth-line ((buffer <buffer>) n)
  (nth n (contents buffer)))

(defmethod current-line (<buffer>)
  (nth (cursor-y <buffer>) (contents <buffer>)))

(defmethod number-of-lines  (<buffer>)
  (length (contents <buffer>)))

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
  "write the contents of buffer line by line onto the standard window"
  (charms:refresh-window (charms:standard-window))
  (when (contents buffer)
    (loop for line in (contents buffer)
       with i = 0 do
         (charms:write-string-at-point (charms:standard-window) line 0 i )
         (incf i))))

(defun insert-after-string (string index elt)
  ;;util
  "insert elt into string after index"
  (or string
    (setf string ""))
  (cl-strings:insert elt string :position index))


(defun insert-after-list (lst index newelt)
  ;;util
  "insert newelt into list after index"
  (push newelt (cdr (nthcdr index lst))) 
  lst)


(defmethod replace-line ((buffer <buffer>) idx string)
  (setf (nth idx (contents buffer)) string))


(defmethod insert-char (char (buffer <buffer>))
  "persist a char entry to a buffer returns the buffer"
  (let* ((y (cursor-y buffer))
         (contents (contents buffer))
         (line-data (nth y contents))
         (new-data (insert-after-string line-data (cursor-x buffer) char)))
   (replace-line buffer y new-data) 
    buffer))


(defun render-char-at-cursor (c buf)
  "render the char in ncurses"
  (charms:write-string-at-point 
   (charms:standard-window) 
   c 
   (cursor-x buf) 
   (cursor-y buf)))

(defun move-cursor-buffer (buffer &key direction)
  (ecase direction
    (:up    (unless (= 0 (cursor-y buffer)) 
              (decf (cursor-y buffer))))
    (:down  (unless (> 0 (number-of-lines buffer)) 
              (incf (cursor-y buffer))))
    (:left  (unless (= 0 (cursor-x buffer)) 
              (decf (cursor-x buffer))))
    (:right (unless (< (length (current-line buffer)) (cursor-x buffer)) 
              (incf (cursor-x buffer))))))

(defun self-insert-command (c buf)
  (insert-char c buf)
  (render-char-at-cursor c buf)
  (move-cursor-buffer buf :direction :right)
  (charms:refresh-window (charms:standard-window)))

(defun handle-input (c buf)
  (case c
    ((nil) nil)
    ((#\k) (move-cursor-buffer buf :direction :up) )
    ((#\j) (move-cursor-buffer buf :direction :down))
    ((#\h) (move-cursor-buffer buf :direction :left))
    ((#\l) (move-cursor-buffer buf :direction :right))
    ((#\s ) (save-buffer buf))
    ((#\q #\Q) (sb-ext:exit))
    (t (self-insert-command (string c) buf) )))


(defun input-loop ()
  (loop
     with buf = (create-buffer "my buf")
     for c = (charms:get-char (charms:standard-window) :ignore-error t)
     do
       (render-buffer buf)
       (charms:move-cursor  (charms:standard-window)
                            (cursor-x buf)
                            (cursor-y buf))
       (handle-input c buf)))

(defun main (args)
  "top level entry"
  (when (second args)
    (create-buffer (second args)))
  (swank-listen)

  (charms:with-curses ()
    (charms:disable-echoing)
    (charms:enable-raw-input :interpret-control-characters t)
    (charms:enable-non-blocking-mode (charms:standard-window))
    (input-loop)))


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
