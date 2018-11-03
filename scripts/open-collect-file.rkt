#lang racket/base
(require racket/gui/base
         racket/class
         setup/dirs
         quickscript)

(script-help-string "Open a file in DrRacket, starting in racket's collections base path.")

;; WARNING: This currently does not work because of `open-in-new-tab`
;; that requires a direct call to the frame in the initial namespace.
;; Needs a particular property to use the namespace anchor?

(define-script open-collects-file
  #:label "Open collects file"
  #:menu-path ("&Utils")
  (λ (str #:frame frame) 
    (define f (get-file "Open a script" #f (find-collects-dir) #f #f '() 
                        '(("Racket" "*.rkt"))))
    (when f
      (send frame open-in-new-tab f))
    #f))

;; TODO: Extend with (find-user-collects-dir) (find-pkgs-dir) (find-user-pkgs-dir)