#lang racket/base
(require quickscript)

(script-help-string "(Example) The simplest script example: reverse the selected string.")

(define-script reverse-selection
  #:label "Reverse selection"
  #:menu-path ("E&xamples")
  (λ (selection) 
    (list->string (reverse (string->list selection)))))
