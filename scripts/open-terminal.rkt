#lang racket/base
(require racket/system
         racket/path
         quickscript/script)

(script-help-string "Open a terminal in the current directory (linux only).")

(define-script open-terminal
  #:label "Open terminal here"
  #:menu-path ("&Utils")
  #:os-types (unix)
  (λ (str #:file f)  
    (define dir (path->string (path-only f)))
    (system (string-append "gnome-terminal"
                           " --working-directory=\"" dir "\""
                           " -t \"" dir "\""
                           "&"))
    #f))

