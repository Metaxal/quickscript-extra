#lang racket/base
(require browser/external
         quickscript)

(script-help-string "More scripts to download with url2script.")

; Launch https://github.com/racket/racket/wiki/Quickscript-Scripts-for-DrRacket in browser
(define-script more-scripts
  #:label "More scripts"
  #:menu-path ("url2script")
  #:help-string "Opens the Racket wiki page for DrRacket Quickscript scripts."
  (λ (str) 
    (send-url "https://github.com/racket/racket/wiki/Quickscript-Scripts-for-DrRacket")
    #f))
    
