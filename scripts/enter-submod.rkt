#lang racket/base
(require racket/class
         quickscript)


(script-help-string
 "Easily enter a submodule (main, test, drracket, etc.) in the interaction window.")
;;; Sends a snippet of text to the interactions window that, once entered,
;;; will enter (evaluate and make visible) the corresponding submodule.

(define ((enter-submod submod) str #:interactions editor)
  (send* editor
    (insert
     (format "(require (only-in racket/enter dynamic-enter!)
           (only-in syntax/location quote-module-path))
(dynamic-enter! (quote-module-path ~a))" submod))))

(define-script enter-drracket
  #:label "&drracket"
  #:menu-path ("&Enter submodule")
  #:shortcut f5
  #:shortcut-prefix (shift)
  (enter-submod 'drracket))

(define-script enter-test
  #:label "&test"
  #:menu-path ("&Enter submodule")
  (enter-submod 'test))

(define-script enter-main
  #:label "&main"
  #:menu-path ("&Enter submodule")
  (enter-submod 'main))
