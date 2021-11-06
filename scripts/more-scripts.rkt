#lang racket/base
(require browser/external
         quickscript)

(script-help-string "More scripts to download with url2script.")

; Launch https://github.com/racket/racket/wiki/Quickscript-Scripts-for-DrRacket in browser
(define-script pasterack
  #:label "More scripts"
  #:menu-path ("&Utils")
  #:help-string "Opens the Racket wiki page for DrRacket Quickscript scripts."
  (λ (str) 
    (send-url "https://github.com/racket/racket/wiki/Quickscript-Scripts-for-DrRacket")
    #f))
    