;; Example for Lisp binary apbplication for distribution and execution in a Docker Container
;;
;; Docker's tutorial
;; https://docs.docker.com/get-started/
;; 
;; Prerequisites for your build environment:
;; 1. Clozure Common Lisp installation
;; 2. Quicklisp installation
;; 
;; load this lisp source code in your build environment (eg linux x86-64 if you're deploying to linux x86-64 containers), then 
;; save the lisp image of the application as an executable binary
#|
(save-application
 #P"app"
 :toplevel-function #'main
 :prepend-kernel t)
|#







(ql:quickload '(hunchentoot))

;; make the web server
(let ((the-server
       (make-instance
	'hunchentoot:easy-acceptor
	:port 8000
	:document-root #P"/Users/frank/Documents/VirtualBox/Shared/"
	:access-log-destination nil
	:message-log-destination nil)))
  (defun start-server ()
    (hunchentoot:start the-server))
  (defun stop-server ()
    (hunchentoot:stop the-server)))

;; make the web server's handler for the home page
;; The homepage will display the host's name and the
;; current time in Unix epoch
(hunchentoot:define-easy-handler (home :uri "/") ()
  (format nil "Hello, world, from ~%~a! The date-time is now ~a."
	  (with-output-to-string (str)
	    (run-program "hostname" () :output str))
	  (get-universal-time)))

;; find and put the thread of the running web server on the foreground
;; so that it keeps listening for HHTP requests rather than quitting as soon as it runs once
;; https://www.coderpoint.info/questions/48103501/deploying-common-lisp-web-applications.html
;; Answer #3 by Ehvince
(defun main ()
  (start-server) ;; our start-app, for example clack:clack-up
  ;; let the webserver run.
  ;; warning: hardcoded "hunchentoot".
  (handler-case
      (bt:join-thread
       (find-if
	(lambda (th)
	  (search "hunchentoot" (bt:thread-name th)))
	(bt:all-threads)))
    ;; Catch a user's C-c
    ;; Must redefine this for CCL because CCL apparently does
    ;; something different with the UNIX interrupt signal
    ;; https://github.com/LispCookbook/cl-cookbook/issues/146
    ;; See ccl:*break-hook* below
    (#+sbcl sb-sys:interactive-interrupt
      #+ccl ccl:interrupt-signal-condition
      #+clisp system::simple-interrupt-condition
      #+ecl ext:interactive-interrupt
      #+allegro excl:interrupt-signal
      () (progn
           (format *error-output* "Aborting.~&")
	   (stop-server)
           (uiop:quit)))
    (error (c) (format t "Woops, an unknown error occured:~&~a~&" c))))





;; It appears that Clozure CL has a different meaning for ccl:interrupt-signal-condition which prevents the code from working on the recent CCL. The fix is suggested here:
;; https://stackoverflow.com/questions/9950680/unix-signal-handling-in-common-lisp/9952183#9952183
(setf ccl:*break-hook* 
      (lambda (cond hook)                              
	(declare (ignore cond hook))
	(format t "Cleaning up ...")
	(ccl:quit)))


;; Handy information for debugging
;; https://forums.docker.com/t/binary-application-runs-in-virtualbox-vms-not-in-docker-containers-no-such-file-or-directory/69017/2



;; Next I'd like to try deploying Lisp programs as scripts to containers built with Lisp images, as in this example of continuous integration:
;; https://lispcookbook.github.io/cl-cookbook/testing.html#continuous-integration 
