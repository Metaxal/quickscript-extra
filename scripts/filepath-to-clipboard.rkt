#lang racket/base
(require quickscript/script)

(script-help-string "Write the path of the current file in the clipboard.")

(define-script filepath-to-clipboard
  #:label "Filepath to clipboard"
  #:menu-path ("&Utils")
  #:output-to clipboard
  (λ(selection #:file f)
    (path->string f)))
