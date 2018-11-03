#lang racket/base
(require quickscript)

(script-help-string
 "(Example) Displays the current file and the current selected string in a message box.")

(define-script current-file-example
  #:label "Current file example"
  #:menu-path ("E&xamples")
  #:output-to message-box
  (λ (selection #:file f) 
    (string-append "File: " (if f (path->string f) "no-file")
                   "\nSelection: " selection)))
