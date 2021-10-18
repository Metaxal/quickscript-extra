#lang racket/base
(require setup/xref
         scribble/xref
         scribble/manual-struct
         racket/class
         racket/list
         racket/format
         racket/string
         quickscript)

(script-help-string "Displays a list of modules that `provide` the procedure under the cursor.")

(define x (load-collections-xref))
(define idx (xref-index x)) ; list of `entry's

(define (search-approximate word)
  (filter (λ (e) (regexp-match word (first (entry-words e)))) ; approximate search
          idx))

(define (search-exact word)
  (sort
   (flatten
    (for/list ([e (in-list idx)]
               #:when (string=? word (first (entry-words e))))
      (exported-index-desc-from-libs (entry-desc e))))
   symbol<?))

(define (entry->list e)
  (list (entry-words e)
        (entry-tag e)
        (entry-desc e)))

(define (entry->string e)
  (define desc (entry-desc e))
  (if (exported-index-desc? desc)
      (format "~a\n  Provided by: ~a\n" 
              (first (entry-words e))
              (exported-index-desc-from-libs desc))
      ""))

(define-script provided-by
  #:label "&Provided by"
  #:help-string "Displays in a message box the list of modules that provided the word under the cursor"
  #:persistent ; to avoid reloading it at each invokation
  #:output-to message-box
  (λ (s #:editor ed) 
    (define start-pos (send ed get-start-position))
    (define end-pos   (send ed get-end-position)) 
    (define start-exp-pos
      (or (send ed get-backward-sexp start-pos) start-pos))
    (define end-exp-pos
      (or (send ed get-forward-sexp (- end-pos 1)) end-pos))
    (define str
      (send ed get-text start-exp-pos end-exp-pos))
    (define res
      (search-exact str))
    (string-append
     "[" str "] is provided (at least) by the following modules:\n\n"
     (if (empty? res)
         "No documented module found."
        (string-join (map ~a res) "\n")))))
