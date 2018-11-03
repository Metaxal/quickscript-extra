#lang racket/base
(require racket/gui/base
         racket/class
         quickscript)

(script-help-string "Jump to a given line number in the current editor.")

(define-script goto-line
  #:label "Go to &line..."
  (λ (str #:editor ed)  
    (define line-str (get-text-from-user "Goto line" "Line number:"
                                         #f
                                         (number->string 
                                          (add1
                                           (send ed position-paragraph 
                                                 (send ed get-end-position))))
                                         #:validate string->number))
    (define line (and line-str (string->number line-str)))
    (when (exact-nonnegative-integer? line)
      (send ed set-position (send ed paragraph-start-position
                                  (sub1 line))))
    #f))
