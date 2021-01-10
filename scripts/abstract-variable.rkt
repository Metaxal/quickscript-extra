#lang racket/base
(require racket/gui
         quickscript)

(script-help-string
 "Create a variable from the selected expression
[video](https://www.youtube.com/watch?v=qgjAZd4eBBY)")

(define-script abstract-variable
  #:label "&Abstract variable"
  #:menu-path ("Re&factor")
  (λ (str) 
    (cond
      [(string=? str "")
       (message-box "Empty selection"
                    "No expression selected"
                    #f
                    '(ok caution))]
      [else
       (define var (get-text-from-user "Variable Abstraction" "Variable name:"
                                       #:validate (λ (s) #t)))
       (if var
           (begin
             (send the-clipboard set-clipboard-string 
                   (string-append "(define " var " " str ")")
                   0)
             var)
           str)])))

;; Select `"badinka"`, then click on Script>Abstract variable, enter `my-var`,
;; add a newline just after `begin` and past what's in the clipboard.
#;(begin
    (string-append "zorglub" "badinka"))