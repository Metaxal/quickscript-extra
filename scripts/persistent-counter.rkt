#lang racket/base
(require quickscript/script)

;; See the manual in the Script/Help menu for more information.

(define count 0)

(define-script increase-counter
  #:label "&Increase counter"
  #:menu-path ("E&xamples" "&Counter")
  #:persistent
  #:output-to message-box
  (λ(selection)
    (set! count (+ count 1))
    (number->string count)))

(define-script show-counter
  #:label "&Show counter"
  #:menu-path ("E&xamples" "&Counter")
  #:persistent
  #:output-to message-box
  (λ(selection)
    (number->string count)))

(define-script show-counter/non-persistent
  #:label "S&how counter (non-persistent)"
  #:menu-path ("E&xamples" "&Counter")
  #:output-to message-box
  (λ(selection)
    (number->string count)))