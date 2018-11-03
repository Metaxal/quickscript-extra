#lang racket/base
(require racket/gui/base
         racket/class
         racket/system
         racket/path
         quickscript
         )

(script-help-string "Some git commands (linux only). Currently meant as a demo.")

;; Modify this command to suit your needs
(define (make-cmd sub-cmd)
  (string-append "xterm -hold -e '" (regexp-replace* #rx"'" sub-cmd "''") "'"))

(define (cmd-system sub-cmd)
  (define cmd (make-cmd sub-cmd))
  ;(message-box "Runnning command" cmd)
  (system (string-append cmd "&")))

(define-syntax-rule (lambda/dir-of-file (f) body ...)
  (lambda (fun _str #:file f)
    (when f
      (define dir (path-only f))
      (parameterize ([current-directory dir])
        body ...
        ))))

(define-script git-commit-file
  #:label "Commit &file"
  #:menu-path ("&Git")
  #:os-types (unix)
  (lambda/dir-of-file (f)
   (define filename (file-name-from-path f))
   (cmd-system (string-append "git commit \"" (path->string filename) "\""))))

(define-script git-add-file
  #:label "A&dd file"
  #:menu-path ("&Git")
  #:os-types (unix)
  (lambda/dir-of-file (f)
   (define filename (file-name-from-path f))
   (cmd-system (string-append "git add \"" (path->string filename) "\""))))

(define-script git-commit-all
  #:label "Commit &all"
  #:menu-path ("&Git")
  #:os-types (unix)
  (lambda/dir-of-file (f)
   ; todo: save all files?
   (cmd-system "git commit -a")))

(define-script git-push
  #:label "&Push"
  #:menu-path ("&Git")
  #:os-types (unix)
  (lambda/dir-of-file (f)
   (cmd-system "git push")))

(define-script git-pull-rebase
  #:label "P&ull --rebase"
  #:menu-path ("&Git")
  #:os-types (unix)
  (lambda/dir-of-file (f)
   (cmd-system "git pull --rebase")))
