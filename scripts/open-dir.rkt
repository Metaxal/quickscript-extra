#lang racket/base
(require racket/system
         racket/path
         quickscript)

(script-help-string "Open the system's file browser in the current directory.")

(define cmd
  (case (system-type 'os)
    [(unix)    "xdg-open"] ; or maybe mimeopen -n ?
    [(windows) "explorer"]
    [(macosx)  "open"]))

(define-script open-file-directory
  #:label "Open file directory"
  #:menu-path ("&Utils")
  (λ (str #:file f)
    (system (string-append cmd " \"" (path->string (path-only f)) "\""))
    #f))
