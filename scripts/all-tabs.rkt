#lang racket/base
(require racket/gui/base
         racket/class
         quickscript)

;;; The default 'Tabs' menu in DrRacket lists only the first 10 tabs.
;;; This script displays all tabs, which is particularly convenient when
;;; there are many tabs and not all of them are visible.

(script-help-string
 "Have a menu that displays all open tabs in DrRacket.")

(define-script all-tabs
  #:label "All tabs"
  (λ (str #:frame fr)  
    (define menu-bar (send fr get-menu-bar))
    (define menu
      (new menu% [parent menu-bar] [label "All Tabs"]
           [demand-callback
            (λ (menu)
              (send fr begin-container-sequence)
              (for ([it (in-list (send menu get-items))])
                (send it delete))
              (new menu-item% [parent menu] [label "&Remove menu"]
                   [callback (λ _ (send menu delete))])
              (for ([t (in-range (send fr get-tab-count))]
                    [tab (in-list (send fr get-tabs))])
                (new menu-item% [parent menu]
                     [label (format "~a: ~a" t (send fr get-tab-filename t))]
                     [callback (λ _ (send fr change-to-tab tab))]))
              (send fr end-container-sequence))]))
    #f))
    
