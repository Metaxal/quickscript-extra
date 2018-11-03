#lang racket/base
(require framework/gui-utils
         racket/gui 
         racket/help
         quickscript)

(script-help-string "Replace patterns in the selected text using regular expressions.")

(editor-set-x-selection-mode #t)

(define str-out #f)
(define str-in #f)
(define f (new dialog% [label "Regexp Replace"]
               [min-width 500]))
(define hp-help (new horizontal-panel% [parent f]))
(define msg-help
  (new message% [parent hp-help] 
       [label "Replace the selected text using an extended regular expression"]))
(define bt-help (new button% [parent hp-help] [label "Regexp Help"]
                     [callback (thunk* (help "Regular expressions N:Printing N:Reading"))]))
(define templates 
  '(("– Templates –" . #f)
    ; title from to protect-from protect-to
    ("Remove trailing spaces" "\\s*$" "" #f #f)
    ("Remove leading spaces" "^\\s*" "" #f #f)
    ("Comment out" "^" ";" #f #f)
    ("Uncomment" "^;" "" #f #f)
    ("Markdown quotes -> @racket[]" "`([^`]+)`" "@racket[\\1]" #f #f)
    ("Markdown item -> @item{}" "\\s*\\*\\s*(.*)\\s*" "@item{\\1}" #f #f)
    ))
(define ch-templates
  (new choice% [parent f]
       [label #f #;"Templates:"]
       [choices (map car templates)]
       [callback (λ (ch ev) 
                   (define sel (send ch get-string-selection))
                   (define l (and sel (dict-ref templates sel)))
                   (when l
                     (send t1 set-value (first l))
                     (send t2 set-value (second l))
                     (send cb1 set-value (third l))
                     (send cb2 set-value (fourth l))))]))
(define hp1 (new horizontal-panel% [parent f]))
(define t1 (new text-field% [parent hp1] [label "Replace:"]))
(define cb1 (new check-box% [parent hp1] [label "Not regexp"]))
(define hp2 (new horizontal-panel% [parent f]))
(define t2 (new text-field% [parent hp2] [label "Replace:"]))
; Hack: Setting the label afterwards ensures both fields have the same size.
(send t2 set-label "With:")
(define cb2 (new check-box% [parent hp2] [label "Not regexp"]))
(define (ok-pressed b ev) 
  (send f show #f)
  (define t1-re ((if (send cb1 get-value) regexp-quote pregexp)
                 (send t1 get-value)))
  (define t2-re ((if (send cb2 get-value) regexp-replace-quote values)
                 (send t2 get-value)))
  (define new-lines
    ; apply the regexes only per line
    (for/list ([line (regexp-split #rx"\n" str-in)])
      (regexp-replace* t1-re line t2-re)))
  (set! str-out (string-join new-lines "\n"))
  ;(set! str-out (regexp-replace* t1-re str-in t2-re)) ; problems with that, e.g., with "\n"
  )
(define (cancel-pressed b ev) 
  (send f show #f))
(define-values (bt-ok bt-cancel)
  (gui-utils:ok/cancel-buttons f ok-pressed cancel-pressed))

;; Performs a (extended) regexp-replace* on the selection.
;; The "from" and "to" patterns are asked in a dialog box.
;; If protect? is checked, the "from" pattern is regexp-quoted.
(define-script regexp-replace-selection
  #:label "Regex replace"
  #:menu-path ("Sele&ction")
  #:help-string "Replace patterns in the selection using regular expressions"
  #:shortcut #\h
  #:shortcut-prefix (ctl)
  #:persistent
  (λ (str) 
    (set! str-in str)
    (set! str-out #f)
    (send t1 focus)
    (send (send t1 get-editor) select-all)
    (send f show #t)
    str-out))

#|
(item-callback "See the manual in the Script/Help \s* menu for \nmore information.")
; for protect, test with \s* and \1
;|#
