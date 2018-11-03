#lang racket/base
(require racket/string
         quickscript)

(script-help-string "Sorts the selected lines in (anti-)alphabetical order.")

(define ((sort-selection cmp) selection)
  (string-join (sort (string-split selection "\n" #:trim? #t)
                     cmp)
               "\n" #:after-last "\n"))

(define-script sort-lines-alpha
  #:label "&Alphabetically"
  #:menu-path ("Sele&ction" "&Sort lines")
  (sort-selection string<=?))

(define-script sort-lines-anti-alpha
  #:label "A&nti-alphabetically"
  #:menu-path ("Sele&ction" "&Sort lines")
  (sort-selection string>=?))
