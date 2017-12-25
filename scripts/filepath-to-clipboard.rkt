#lang racket/base
(require quickscript/script)

(define-script filepath-to-clipboard
  #:label "Filepath to clipboard"
  #:menu-path ("&Utils")
  #:output-to clipboard
  (λ(selection #:file f)
    (path->string f)))
