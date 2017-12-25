#lang racket/base
(require quickscript/script)

(define-script insert-complete-script
  #:label "Insert complete script"
  #:menu-path ("E&xamples")
  (λ(selection)
    #<<EOS
(define-script a-complete-script
  #:label "Full script"
  #:help-string "A complete script showing all properties and arguments"
  #:menu-path ("Submenu" "Subsubmenu")
  #:shortcut #\a
  #:shortcut-prefix (ctl shift)
  #:output-to selection ; or message-box, new-tab, clipboard, #f
  #:persistent ; or remove this line
  (λ(selection #:editor ed #:frame fr #:interactions ints #:file f)
    "Hello world!"))
EOS
    ))
