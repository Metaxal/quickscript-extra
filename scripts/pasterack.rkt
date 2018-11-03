#lang racket/base
(require browser/external
         quickscript)

(script-help-string "Opens Pasterack in the browser.")

; Launch http://pasterack.org/ in browser
(define-script pasterack
  #:label "Pasterack (browser)"
  #:menu-path ("&Utils")
  #:help-string "Opens 'PasteRack' An evaluating pastebin for Racket."
  (λ (str) 
    (send-url "http://pasterack.org/")
    #f))
