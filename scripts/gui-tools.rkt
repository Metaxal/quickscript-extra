#lang at-exp racket/base
(require quickscript)

(script-help-string "Code snippets for racket/gui widgets. Meant as a demo.")

(define-script add-frame
  #:label "Add frame"
  #:menu-path ("Gui tools")
  (λ (str) 
    (set! str (if (string=? str "") "my-frame" str))
@string-append{
(define @str
  (new frame%
       [label "@str"]
       [min-width 200] [min-height 200]))
}))

(define-script add-message
  #:label "Add message"
  #:menu-path ("Gui tools")
  (λ (str) 
    (set! str (if (string=? str "") "my-message" str))
    @string-append{
(new message% [parent #f] [label "@str"])
}))


