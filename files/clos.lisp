(declaim (optimize (speed 3) (space 1) (safety 0) (debug 0) (compilation-speed 0)))
;; clos.lisp -- CLOS benchmarking code
;;
;; Author: Eric Marsden <emarsden@laas.fr>
;; Time-stamp: <2003-12-30 emarsden>
;;
;;
;; This file does some benchmarking of CLOS functionality. It creates
;; a class hierarchy of the form
;;
;;                         class-0-0
;;                      /     |        \
;;                    /       |          \
;;                  /         |            \
;;          class-0-1      class-1-1     . class-2-1
;;             |         /    |     .  .   /    |
;;             |     /      . |  .       /      |
;;             |  /     .     |        /        |
;;          class-0-2      class-1-2       class-2-2
;;
;;
;; where the shape of the hierarchy is controlled by the parameters
;; +HIERARCHY-DEPTH+ and +HIERARCHY-WIDTH+. Note that classes to the
;; left of the diagram have more superclasses than those to the right.
;; It then defines methods specializing on each class (simple methods,
;; after methods and AND-type method combination), and
;; INITIALIZE-INSTANCE methods. The code measures the speed of
;;
;;    - creation of the class hierarchy (time taken to compile and
;;      execute the DEFCLASS forms)
;;
;;    - instance creation
;;
;;    - method definition (time taken to compile and execute the
;;      DEFMETHOD forms)
;;
;;    - execution of "simple" method invocations, both with and
;;      without :after methods
;;
;;    - execution of "complex" method invocations (using AND-type
;;      method combination)
;;
;;
;; This code is probably not representative of real usage of CLOS, but
;; should give an idea of the speed of a particular CLOS
;; implementation.
;;
;; Note: warnings about undefined accessors and types are normal when
;; compiling this code.


(in-package :cl-bench.clos)

(define-symbol-macro +hierarchy-depth+ 10)
(define-symbol-macro +hierarchy-width+ 5)


;; the level-0 hierarchy
(defclass class-0-0 () ())

(defvar *instances* (make-array +hierarchy-width+ :element-type 'class-0-0))


(defgeneric simple-method (a b))

(defmethod simple-method ((self class-0-0) other) other)

#-(or clisp poplog)
(defgeneric complex-method (a b &rest rest)
  (:method-combination and))

#-(or clisp poplog)
(defmethod complex-method and ((self class-0-0) other &rest rest)
   (declare (ignore rest))
   other)

(defmacro make-class-name (depth width)
  (with-standard-io-syntax
    `(intern (format nil "CLASS-~d-~d" ,depth ,width))))

(defmacro make-attribute-name (depth width)
  (with-standard-io-syntax
    `(intern (format nil "ATTRIBUTE-~d-~d" ,depth ,width))))

(defmacro make-initarg-name (depth width)
  (with-standard-io-syntax
    `(intern (format nil "INITARG-~d-~d" ,depth ,width) :keyword)))

(defmacro make-accessor-name (depth width)
  (with-standard-io-syntax
    `(intern (format nil "GET-ATTRIBUTE-~d-~d" ,depth ,width))))

(defmacro class-definition (depth width)
  `(defclass ,(make-class-name depth width)
    ,(loop :for w :from width :below +hierarchy-width+
           :collect (make-class-name (1- depth) w))
    (( ,(make-attribute-name depth width)
      :initarg ,(make-initarg-name depth width)
      :initform (* ,depth ,width)
      :accessor ,(make-accessor-name depth width)))))

(defmacro init-instance-definition (depth width)
  `(defmethod initialize-instance :after ((self ,(make-class-name depth width)) &rest initargs)
    (declare (ignore initargs))
    (incf (,(make-accessor-name depth width) self))))

(defmacro simple-method-definition (depth width)
  `(defmethod simple-method ((self ,(make-class-name depth width))
                      (n number))
    (* n (call-next-method) (,(make-accessor-name depth width) self))))

(defmacro complex-method-definition (depth width)
  `(defmethod complex-method and ((self ,(make-class-name depth width))
                                  (n number) &rest rest)
    (declare (ignore rest))
    (,(make-accessor-name depth width) self)))

(defmacro after-method-definition (depth width)
  `(defmethod simple-method :after ((self ,(make-class-name depth width))
                             (n number))
    (setf (,(make-accessor-name depth width) self) ,(* depth width width))))

(defun defclass-forms ()
  (let (forms)
    (loop :for width :to +hierarchy-width+ :do
         (push `(defclass ,(make-class-name 1 width) (class-0-0) ()) forms))
    (loop :for dpth :from 2 :to +hierarchy-depth+ :do
          (loop :for wdth :to +hierarchy-width+ :do
                (push `(class-definition ,dpth ,wdth) forms)
                (push `(init-instance-definition ,dpth ,wdth) forms)))
    (nreverse forms)))

(defun defmethod-forms ()
  (let (forms)
    (loop :for dpth :from 2 to +hierarchy-depth+ :do
          (loop :for wdth :to +hierarchy-width+ :do
                (push `(simple-method-definition ,dpth ,wdth) forms)
                #-(or clisp poplog)
                (push `(complex-method-definition ,dpth ,wdth) forms)))
    (nreverse forms)))

(defun after-method-forms ()
  (let (forms)
    (loop :for depth :from 2 :to +hierarchy-depth+ :do
          (loop :for width :to +hierarchy-width+ :do
                (push `(after-method-definition ,depth ,width) forms)))
    (nreverse forms)))

(defun run-defclass ()
  (dolist (form (defclass-forms))
    (funcall (compile nil `(lambda () ,form)))))

(defun run-defmethod ()
  (dolist (form (defmethod-forms))
    (funcall (compile nil `(lambda () ,form)))))

(defun add-after-methods ()
  (dolist (form (after-method-forms))
    (funcall (compile nil `(lambda () ,form)))))

(defun make-instances ()
  (dotimes (i 5000)
    (dotimes (w +hierarchy-width+)
      (setf (aref *instances* w)
            (make-instance (make-class-name +hierarchy-depth+ w)
                           (make-initarg-name +hierarchy-depth+ w) 42))
      `(incf (slot-value (aref *instances* w) ',(make-attribute-name +hierarchy-depth+ w))))))

;; the code in the function MAKE-INSTANCES is very difficult to
;; optimize, because the arguments to MAKE-INSTANCE are not constant.
;; This test attempts to simulate the common case where some of the
;; parameters to MAKE-INSTANCE are constants.
(defclass a-simple-base-class ()
  ((attribute-one :accessor attribute-one
                  :initarg :attribute-one
                  :type string)))

(defclass a-derived-class (a-simple-base-class)
  ((attribute-two :accessor attribute-two
                  :initform 42
                  :type integer)))

(defun make-instances/simple ()
  (dotimes (i 5000)
    (make-instance 'a-derived-class
                   :attribute-one "The first attribute"))
  (dotimes (i 5000)
    (make-instance 'a-derived-class
                   :attribute-one "The non-defaulting attribute")))


(defun methodcall/simple (num)
  (dotimes (i 5000)
    (simple-method (aref *instances* num) i)))

(defun methodcalls/simple ()
  (dotimes (w +hierarchy-width+)
    (methodcall/simple w)))

(defun methodcalls/simple+after ()
  (add-after-methods)
  (dotimes (w +hierarchy-width+)
    (methodcall/simple w)))

#-(or clisp poplog)
(defun methodcall/complex (num)
  (dotimes (i 5000)
    (complex-method (aref *instances* num) i)))

#-(or clisp poplog)
(defun methodcalls/complex ()
  (dotimes (w +hierarchy-width+)
    (methodcall/complex w)))



;;; CLOS implementation of the Fibonnaci function, with EQL specialization

(defmethod eql-fib ((x (eql 0)))
   1)

(defmethod eql-fib ((x (eql 1)))
   1)

; a method for all other cases
(defmethod eql-fib (x)
   (+ (eql-fib (- x 1))
      (eql-fib (- x 2))))


(defun run-eql-fib ()
  (eql-fib 30))

;; EOF
