#lang racket/base
(require racket/system
         racket/path
         quickscript)

(script-help-string "Open a terminal in the current directory.")

(define-script open-terminal
  #:label "Open terminal here"
  #:menu-path ("&Utils")
  #:os-types (unix macosx)
  #:output-to message-box
  
  (cond

    [(equal? (system-type 'os) 'unix)
     (λ (str #:file f)  
       (define dir (path->string (path-only f)))
       (system (string-append "gnome-terminal"
                              " --working-directory=\"" dir "\""
                              " -t \"" dir "\""
                              "&"))
       #f)]
    [(equal? (system-type 'os) 'macosx)
     (λ (str #:file f)  
       (define dir (path->string (path-only f)))
       (define osascriptdir (string-append
                             (path->string (find-system-path 'pref-dir))
                             "quickscript/user-scripts/"))
       (system (string-append "osascript -e 'tell app \"Terminal\" to do script \"cd \\\"" dir "\\\"\"'" ))
       #f)]))
