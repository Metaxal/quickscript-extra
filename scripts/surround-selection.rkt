#lang racket/base
(require quickscript)

(script-help-string "(Example) Surround the selected text with various characters.")

(define-script surround-with-dashes
  #:label "Surround with dashes"
  #:menu-path ("E&xamples" "&Surround")
  #:help-string "Surrounds the selection with dashes"
  (λ (selection) 
    (string-append "-" selection "-")))

(define-script surround-with-stars
  #:label "Surround with stars"
  #:menu-path ("E&xamples" "&Surround")
  #:help-string "Surrounds the selection with stars"
  (λ (selection) 
    (string-append "*" selection "*")))

(define-script surround-with-slashes
  #:menu-path ("E&xamples" "&Surround")
  #:label "Surround with slashes"
  (λ (selection) 
    (string-append "/" selection "/")))
