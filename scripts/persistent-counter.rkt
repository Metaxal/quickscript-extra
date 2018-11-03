#lang racket/base
(require quickscript)

(script-help-string "(Example) Shows how the `#:persistent` property works.")

(define count 0)

(define-script increase-counter
  #:label "&Increase counter"
  #:menu-path ("E&xamples" "&Counter")
  #:persistent
  #:output-to message-box
  (λ (selection) 
    (set! count (+ count 1))
    (number->string count)))

(define-script show-counter
  #:label "&Show counter"
  #:menu-path ("E&xamples" "&Counter")
  #:persistent
  #:output-to message-box
  (λ (selection) 
    (number->string count)))

(define-script show-counter/non-persistent
  #:label "S&how counter (non-persistent)"
  #:menu-path ("E&xamples" "&Counter")
  #:output-to message-box
  (λ (selection) 
    (number->string count)))