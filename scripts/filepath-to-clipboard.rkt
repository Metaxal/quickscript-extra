#lang racket/base
(require quickscript
         racket/path)

(script-help-string "Write the path of the current file in the clipboard.")

(define-script filepath-to-clipboard
  #:label "Filepath to clipboard"
  #:menu-path ("&Utils")
  #:output-to clipboard
  (λ (selection #:file f) 
    (path->string f)))

(define-script directory-to-clipboard
  #:label "File directory to clipboard"
  #:menu-path ("&Utils")
  #:output-to clipboard
  (λ (selection #:file f) 
    (path->string (path-only f))))
