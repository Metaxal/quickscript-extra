#lang racket/base
(require racket/class
         racket/list
         racket/format
         racket/gui/base
         quickscript
         (only-in srfi/1 list-index))

(script-help-string "(Example) Move DrRacket's tabs around.")

(define-script move-left
  #:label "Move left"
  #:menu-path ("E&xamples" "&Tabs")
  #:persistent ; for loading speed 
  (λ (str #:frame fr) 
    (send fr move-current-tab-left)
    #f))

(define-script move-right
  #:label "Move right"
  #:menu-path ("E&xamples" "&Tabs")
  #:persistent
  (λ (str #:frame fr) 
    (send fr move-current-tab-right)
    #f))

(define-script move-to-last
  #:label "Move to last"
  #:menu-path ("E&xamples" "&Tabs")
  #:persistent
  (λ (str #:frame fr) 
    (define cur-tab (send fr get-current-tab))
    (define tabs (send fr get-tabs))
    (define cur-tab-idx (list-index (λ (t) (eq? t cur-tab)) tabs))
    (send fr reorder-tabs 
          (append (remove cur-tab-idx (range (length tabs)))
                  (list cur-tab-idx)))
    #f))

(define-script move-to-first
  #:label "Move to first"
  #:menu-path ("E&xamples" "&Tabs")
  #:persistent
  (λ (str #:frame fr) 
    (define cur-tab (send fr get-current-tab))
    (define tabs (send fr get-tabs))
    (define cur-tab-idx (list-index (λ (t) (eq? t cur-tab)) tabs))
    (send fr reorder-tabs 
          (cons cur-tab-idx
                (remove cur-tab-idx (range (length tabs)))))
    #f))

(define-script reverse-tabs
  #:label "Reverse tabs"
  #:menu-path ("E&xamples" "&Tabs")
  #:persistent
  (λ (str #:frame fr) 
    (send fr reorder-tabs 
          (reverse (range (length (send fr get-tabs)))))
    #f))
