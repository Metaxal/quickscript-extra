#lang racket/base
(require quickscript/script
         racket/class)

(define-script number-tabs
  #:label "Number of tabs"
  #:menu-path ("E&xamples")
  #:output-to message-box
  (λ(selection #:frame fr)
    (format "Number of tabs in DrRacket: ~a"
            (send fr get-tab-count))))
