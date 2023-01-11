#lang racket/base
(require racket/class
         racket/dict
         racket/list
         quickscript)

(script-help-string "Word completion from a given user dictionary")
;;; Replaces the text abbreviation right before the caret by some expanded text

;;; *** How to customize this script ***
;;;
;;; 1. Click on Scripts|Manage|Library…
;;; 2. Select the ".../quickscript-extra/scripts" directory in the left panel
;;; 3. Select the "complete-word" scripts in the right panel
;;; 4. Click on Shadow (and read the message)
;;; 5. Customize the script by modifying the `words` parameters, for example
#;(shadow:words '(("L" "(λ (" ") )") ; replace L with (λ () )
                  ("frame" "(define fr (new frame% [label \""
                           "\"]))\n(send fr show #true)")))
;;; 6. Save the file, reload the menu (Scripts|Manage|Reload menu).
;;;
;;; Now try the script: In any tab, type `frame` (without quotes) followed
;;; by `c:s:/`.
;;;
;;; You can also customize the shortcut defined in the shadow script.



(provide words
         default-words)

(define default-words
  '(("dspr"  "(define-syntax-parse-rule (" ")\n  )")
    ("dsr"   "(define-syntax-rule (" ")\n  )")
    ("ds"    "(define-syntax " "\n  )")
    ("sr"    "(syntax-rules ()\n    [(_ " ")])")
    ("sc"    "(syntax-case stx ()\n    [(_ " ")])")
    ("dsm"   "(define-simple-macro (" ")\n  )")
    ("lbd"   "(λ (" ") )")
    ("param" "(parameterize ([current-" "])\n  )")
    ("wh"    "(with-handlers ([exn:" "])\n  )")
    ("wiff"  "(with-input-from-file " "\n  (λ _ ))")
    ("wotf"  "(with-output-to-file " " #:exists 'replace\n  (λ _ ))")
    
    ; slideshow:
    ("slide"    "(slide #:title \"" "\"\n       )")
    ("item"     "@item{" "}")
    ("subitem"  "@subitem{" "}")
    ("$"        "@${" "}")
    ("$$"       "@$${" "}")

    ; Qi:
    ("flow"    "(☯ " ")")
    ("sep"     "△ " "")
    ("collect" "▽ " "")
    ("ground"  "⏚" "")
    ))

(define words (make-parameter default-words))

(define-script complete-word
  #:label "Auto-complete"
  #:shortcut #\/
  #:shortcut-prefix (ctl shift)
  (λ (s #:editor ed) 
    (define pos (send ed get-end-position)) 
    (define str
      (send ed get-text 
            (send ed get-backward-sexp pos) 
            pos))
    (define str-ext (dict-ref (words) str #f))
    (define left (if (list? str-ext) (first str-ext) str-ext))
    (define right (and (list? str-ext) (second str-ext)))
    (when str-ext
      (send ed begin-edit-sequence)
      (send ed select-backward-sexp)
      (send ed insert left)
      (when right
        (define ipos (send ed get-start-position))
        (send ed insert right)
        (send ed set-position ipos))
      (send ed end-edit-sequence))
    #f))
  
#;(
   item
   para
   wh
   $$
   )
