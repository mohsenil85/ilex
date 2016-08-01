(in-package :cl-user)
(defpackage ilex
  (:use :cl
        :charms)
  (:export #:main))
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

(defun main (args)
  (declare (ignore args ))
  "Start the timer program."
  (charms:with-curses ()
    (charms:disable-echoing)
    (charms:enable-raw-input :interpret-control-characters t)
    (charms:enable-non-blocking-mode charms:*standard-window*)

    (loop :named driver-loop
       :with x := 0                  ; Cursor X coordinate
       :with y := 0                  ; Cursor Y coordinate
       :for c := (charms:get-char charms:*standard-window*
                                  :ignore-error t)
       :do (progn
             ;; Refresh the window
             (charms:refresh-window charms:*standard-window*)

             ;; Process input
             (case c
               ((nil) nil)
               ((#\w) (decf y))
               ((#\a) (decf x))
               ((#\s) (incf y))
               ((#\d) (incf x))
               ((#\Space) (charms:write-char-at-point *standard-window* c (random 10) (random 10) ))
               ((#\q #\Q) (return-from driver-loop)))

             ;; Normalize the cursor coordinates
             (multiple-value-bind (width height)
                 (charms:window-dimensions charms:*standard-window*)
               (setf x (mod x width)
                     y (mod y height)))

             ;; Move the cursor to the new location
             (charms:move-cursor charms:*standard-window* x y)))))


