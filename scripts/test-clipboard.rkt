#lang racket/base
(require quickscript/script)

(define-script selection-to-clipboard
  #:label "Selection to clipboard"
  #:menu-path ("E&xamples")
  #:output-to clipboard
  (λ(selection)
    selection))

