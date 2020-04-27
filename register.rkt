#lang racket/base
(require quickscript/library
         racket/runtime-path
         (for-syntax racket/base))

;;; To register the script directory to use with quickscript
;;; run this file in DrRacket, or on the command line with
;;; $ racket -l quickscript-extra/register

(define-runtime-path script-dir "scripts")
(add-third-party-script-directory! script-dir)

(begin-for-syntax
  ;; To be displayed after setup
  (displayln "Register me as a quickscript directory (on first setup only) with:
racket -l quickscript-extra/register"))

