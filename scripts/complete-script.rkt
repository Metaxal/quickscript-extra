#lang racket/base
(require quickscript/script)

;; See the manual in the Script/Help menu for more information.

(define-script a-complete-script2
  #:label "Full script"
  #:help-string "A complete script showing all properties and arguments"
  #:menu-path ("E&xamples" "Su&bmenu" "Subsu&bmenu")
  #:shortcut #\a
  #:shortcut-prefix (ctl shift)
  #:output-to selection
  #:persistent
  (λ(selection #:editor ed #:frame fr #:interactions ints #:file f)
    "Hello world!"))
