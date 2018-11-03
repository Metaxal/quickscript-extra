#lang racket/base
(require racket/gui/base
         racket/class
         quickscript)

(script-help-string "(Example) Shows how to dynamically add a menu to DrRacket.")

(define-script add-menu
  #:label "Add menu"
  #:menu-path ("E&xamples")
  (λ (str #:frame fr)  
    (define menu-bar (send fr get-menu-bar))
    (define menu (new menu% [parent menu-bar] [label "M&y Menu"]))
    (new menu-item% [parent menu] [label "&Remove me"]
         [callback (λ _ (send menu delete))])
    (define count 0)
    (new menu-item% [parent menu] [label "&Count me"]
         [callback (λ _ 
                     (set! count (add1 count))
                     (message-box "Count" (string-append "Count: " (number->string count)))
                     )])
    #f))

