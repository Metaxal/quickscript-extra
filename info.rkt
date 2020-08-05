#lang info
(define collection "quickscript-extra")
(define deps '("base"
               "quickscript"
               "at-exp-lib"
               "drracket"
               "gui-lib"
               "pict-lib"
               "racket-index"
               "scribble-lib"
               "srfi-lite-lib"
               "web-server-lib"))
(define build-deps '(#;"scribble-lib" "racket-doc" "rackunit-lib"))
(define scribblings '(("scribblings/quickscript-extra.scrbl" ())))
(define pkg-desc "Description Here")
(define version "0.0")
(define pkg-authors '(orseau))
