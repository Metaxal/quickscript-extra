#lang racket/base
(require racket/system
         racket/path
         quickscript)

(script-help-string "Open a terminal in the current directory.")

(define-script open-terminal
  #:label "Open terminal here"
  #:menu-path ("&Utils")
  #:os-types (unix macosx windows)
  #:output-to message-box

  (case (system-type 'os)
    [(unix)
     (λ (str #:file f)  
       (define dir (path->string (path-only f)))
       (system (string-append "gnome-terminal"
                              " --working-directory=\"" dir "\""
                              " -t \"" dir "\""
                              "&"))
       #f)]
    [(macosx)
     (λ (str #:file f)  
       (define dir (path->string (path-only f)))
       (system
        (string-append "osascript -e 'tell app \"Terminal\" to do script \"cd \\\"" dir "\\\"\"'" ))
       #f)]
    [(windows)
     (λ (str #:file f)
       (define dir (path->string (path-only f)))
       (system (string-append "cmd /c start cmd.exe /K \"cd " dir)))]
       (shell-execute #f "cmd.exe" "" dir 'sw_shownormal))]))