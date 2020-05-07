#lang racket/base

(require quickscript
         racket/format
         racket/class
         racket/path
         racket/gui/base)

(script-help-string
 "Extracts a block of code out of its context and generates a function and a call
 [video](https://www.youtube.com/watch?v=XinMxDLZ7Zw)")

;;; How to use:
;;; . Select a block of code
;;; . Click on Scripts | extract-function (Ctrl-Shift-X)
;;; . Enter a function name
;;; . Move the cursor to the insertion point (don't edit the file!)
;;; . Click on Scripts | put-function (Ctrl-Shift-Y)


;=================================;
;=== Function extraction tools ===;
;=================================;

(require racket/dict
         racket/list
         racket/match
         racket/port
         syntax/modread
         drracket/check-syntax)

(module+ test
  (require rackunit))

(struct scope (start end)
  #:transparent
  #:mutable)

(define (scope-span scope)
  (- (scope-end scope)
     (scope-start scope)))

;; If strict is #t, then pos-or-scope must be strictly within scope, and not equal
;; (useful when scope is for a list and we want to check if something is inside the list,
;; and not on the opening parenthesis).
(define (in-scope? pos-or-scope scope #:strict? [strict? #f])
  (define start (+ (scope-start scope) (if strict? 1 0)))
  (define end (- (scope-end scope) 1)) ; unconditional
  (if (scope? pos-or-scope)
    (and (<= start (scope-start pos-or-scope) end)
         (<= start (- (scope-end pos-or-scope) 1) end))
    (<= start pos-or-scope end)))

(define (syntax-scope stx)
  ;; syncheck's first position is 0 (right before the # of #lang)
  ;; but syntax-position starts at 1.
  (define start (+ -1 (syntax-position stx))) ; -1 for syncheck
  (define span (syntax-span stx))
  (define end (+ start span))
  (scope start end))

;; Symbols with occurrences start pos, end pos and span
(define (id-scopes stx)
  (define sym+scopes '())
  (let loop ([stx stx])
    (define x (syntax-e stx))
    (define sc (syntax-scope stx))
    (cond [(list? x)
           (for-each loop x)]
          [(symbol? x)
           (set! sym+scopes (cons (list x sc) sym+scopes))])) ; else nothing
  (reverse sym+scopes))


;; Returns a dict of scope -> source-scope
;; The only function that uses check-syntax (show-content)
(define (syntax->source-scope-dict mod-stx)
  (define h (make-hash))
  (for ([v (in-list (show-content mod-stx))])
    (match v
      [(vector 'syncheck:add-arrow/name-dup/pxpy
               start-left start-right start-px start-py
               end-left   end-right   end-px   end-py
               actual?
               phase-level
               require-arrow
               name-dup?)
       (define start-scope (scope start-left start-right))
       (hash-set! h start-scope start-scope)
       (hash-set! h (scope end-left end-right) start-scope)]
      [else '()]))
  h)

;; Returns two lists:
;; The list of ids that are bound in from-scope but won't be bound in dest-pos,
;; and the list of ids outside of from-scope that are defined in from-scope
;; but will be undefined after moving the code to dest-pos.
(define (unbound-ids mod-stx from-scope dest-pos)
  ;; if dest-pos is after the scope of the module, 
  (set! dest-pos dest-pos)
  (define source-scope-dict (syntax->source-scope-dict mod-stx))
  (define sym+scopes (id-scopes mod-stx))
  (define to-scope (smallest-common-scope mod-stx dest-pos))
  (values
   ;; ids in from-scope that will become unbound at dest-pos
   (filter-map
    (λ (s)
      (define sym-scope (second s))
      (define sym-start (scope-start sym-scope))
      (and (in-scope? sym-start from-scope)
           (let ([src (dict-ref source-scope-dict sym-scope #f)])
             (and src
                  (not (in-scope? (scope-start src) from-scope))
                  (let ([sym-def-scope (smallest-common-scope mod-stx sym-start (scope-start src))])
                    (and (not (in-scope? dest-pos sym-def-scope #:strict? #t))
                         (list (first s) sym-scope src)))))))
    sym+scopes)
   ;; ids outside of from-scope that will become unbound once
   ;; the code is moved to dest-pos
   (filter-map
    (λ (s)
      (define sym-scope (second s))
      (define sym-start (scope-start sym-scope))
      (and (not (in-scope? sym-start from-scope))
           (let ([src (dict-ref source-scope-dict sym-scope #f)])
             (and src
                  (in-scope? (scope-start src) from-scope)
                  (list (first s) sym-scope src)))))
    sym+scopes)))

;; Returns the smallest scope of a list containing all positions of pos-or-scope-list.
;; If fix is not #f and the smallest common scope is the scope of the module,
;; then the end of the scope is set to +inf.0, to account for whitespaces at the end
;; of the file, which position may lie outside the module scope.
(define (smallest-common-scope mod-stx
                               #:fix-module-scope? [fix? #t]
                               . pos-or-scope-list)
  (unless (syntax? mod-stx)
    (raise-argument-error 'smallest-common-scope "syntax?" mod-stx))
  (define module-scope (syntax-scope mod-stx))
  (define res
    (let loop ([stx mod-stx])
      (define x (syntax-e stx))
      (define sc (syntax-scope stx))
      (and (list? x)
           (andmap (λ (p) (in-scope? p sc))
                   pos-or-scope-list)
           (or (ormap loop x)
               sc))))
  (if (and fix? (or (equal? res module-scope)
                    (not res)))
    (scope (scope-start module-scope) +inf.0)
    res))

(define (find-sexp stx from-scope)
  (let loop ([stx stx])
    (define x (syntax-e stx))
    (define sc (syntax-scope stx))
    (cond [(equal? sc from-scope)
           (syntax->datum stx)]
          [(list? x)
           (ormap loop x)]
          [else #f])))

;; TODO: some shadowing cases will not work such as
#;(let ([a 5])
    {+ a 5}
    (let ([a 'nowin])
      'TO))

;; See def of `show-content`.
(define (module-port->syntax port source)
  (port-count-lines! port)
  (with-module-reading-parameterization
    (λ ()
      (read-syntax source port))))

(define (module-file->syntax f)
  (call-with-input-file f
    (λ (port)
      (module-port->syntax port f))))

(define (module-string->syntax str [source #f])
  (call-with-input-string str
    (λ (port)
      (module-port->syntax port (or source (build-path (current-directory) "dummy.rkt"))))))


;=============;
;=== Tests ===;
;=============;


; The 'position' script helps finding out the positions and scopes (copies into the clipboard,
; make sure to reload the menu).
#|
#lang racket/base

(require quickscript
         racket/class)

(define-script position
  #:label "position"
  #:output-to clipboard
  (λ (selection #:editor ed)
    (define start (send ed get-start-position))
    (define end (send ed get-end-position))
    (if (= start end)
      (format "~a" start)
      (format "~a ~a" start end))))
|#

(module+ test
  (let ()
    ;; Tricky case due to module not spanning the whole string
    (define txt
      "#lang racket

(λ (abc)
  (+ abc 3))



")
    (define stx (module-string->syntax txt))
    (define sym+scopes (id-scopes stx))
    (define d (syntax->source-scope-dict stx))
    (let ([scopes-from-syncheck (map second sym+scopes)])
      (for ([(k v) (in-dict d)])
        (check member k scopes-from-syncheck)
        (check member v scopes-from-syncheck)))
    ; (+ abc 3)@
    (define from-scope (scope 25 34))
    (check-equal? (smallest-common-scope stx from-scope)
                  from-scope)
    (for ([dest-pos (in-list '(13 35))])
      (check-equal? (smallest-common-scope stx dest-pos)
                    (scope 6 +inf.0))
      (define-values (in-ids out-ids)
        (unbound-ids stx from-scope dest-pos)) 
      (check-equal? (remove-duplicates (map first in-ids))
                    '(abc))
      (check-equal? (remove-duplicates (map first out-ids))
                    '())))

  )

(module+ test
  (let ()
    (define txt
      "#lang racket

(define a 1)

(let ([e 4])
  (define b (+ e 1))
  (define c (+ a 3))
  (displayln b)
  (define d 4)
  (+ b c d))

")
    (define stx (module-string->syntax txt))
    (define sym+scopes (id-scopes stx))
    (define d (syntax->source-scope-dict stx))
    (let ([scopes-from-syncheck (map second sym+scopes)])
      (for ([(k v) (in-dict d)])
        (check member k scopes-from-syncheck)
        (check member v scopes-from-syncheck)))
    (define from-scope (scope 41 99))
    (check-equal? (smallest-common-scope stx from-scope)
                  (scope 28 126))
    (for ([dest-pos (in-list '(13 26 28 126 128))])
      (if (= dest-pos 28)
        (check-equal? (smallest-common-scope stx dest-pos)
                      (scope 28 126)
                      (~a dest-pos))
        (check-equal? (smallest-common-scope stx dest-pos)
                      (scope 6 +inf.0)
                      (~a dest-pos)))
      (define expected-ins '(e))
      (define expected-outs '(b c))
      (define-values (in-ids out-ids)
        (unbound-ids stx from-scope dest-pos)) 
      (check-equal? (remove-duplicates (map first in-ids))
                    expected-ins
                    (~a dest-pos))
      (check-equal? (remove-duplicates (map first out-ids))
                    expected-outs
                    (~a dest-pos)))
    (for ([dest-pos (in-list '(40))])
      (define-values (in-ids out-ids)
        (unbound-ids stx from-scope dest-pos)) 
      (check-equal? (remove-duplicates (map first in-ids))
                    '()
                    (~a dest-pos))
      (check-equal? (remove-duplicates (map first out-ids))
                    '(b c)
                    (~a dest-pos))))
  )

;===============;
;=== Scripts ===;
;===============;

;;; TODO: A script that displays the list of in and out ids for a selected block,
;;; independently of the dest-pos site? (or dest-pos = module?)

;; Returns the call-site and fun-sites strings.
;; Was created with this very script :)
(define (make-call+fun-sites from-string fun-name in-ids out-ids)
  ;; The two common way to select text is either sexp-based or line based.
  ;; If the last charater of the selection is a newline (line-based),
  ;; put one back in.
  (define last-pos (- (string-length from-string) 1))
  (define has-newline?
    (eqv? #\newline (string-ref from-string last-pos)))
  (when has-newline?
    (set! from-string (substring from-string 0 last-pos)))
  (define maybe-newline (if has-newline? "\n" ""))
  (define header
    (string-append "(" (apply ~a fun-name in-ids #:separator " ") ")"))
  (define call-site
    (cond [(empty? out-ids) (string-append header maybe-newline)]
          [(empty? (rest out-ids))
           (string-append "(define " (~a (first out-ids))
                          " " header ")" maybe-newline)]
          [else
           (string-append "(define-values " (~a out-ids)
                          "\n" header ")" maybe-newline)]))
  (define fun1
    (string-append "(define " header "\n"
                   from-string))
  (define fun-site
    (cond [(empty? out-ids)
           (string-append fun1 ")\n")]
          [(empty? (rest out-ids))
           (string-append fun1 "\n" (~a (first out-ids)) ")\n")]
          [else
           (string-append fun1 "\n(values " (apply ~a #:separator " " out-ids) "))\n")]))
  (values call-site fun-site))
  
(define start #f)
(define end #f)
(define fun-name #f)
(define txt-length #f)

(define-script extract-function
  #:label "extract-function"
  #:shortcut #\x
  #:shortcut-prefix (ctl shift)
  #:persistent
  (λ (selection #:editor ed #:frame fr)
    (define name (get-text-from-user "Function name"
                                     "Choose a name for the new function"
                                     fr
                                     "FOO"
                                     '(disallow-invalid)
                                     #:validate (λ (s) (not (regexp-match #px"\\s|^#|\"|'" s)))))
    (when name
      (set! fun-name name)
      (set! start (send ed get-start-position))
      (set! end (send ed get-end-position))
      (set! txt-length (string-length (send ed get-text))))
    #f))

(define-script put-function
  #:label"put-function"
  #:shortcut #\y
  #:shortcut-prefix (ctl shift)
  #:persistent
  (λ (selection #:file f #:editor ed #:frame fr)
    (when start
      (define txt (send ed get-text))
      (cond
        [(not (= (string-length txt) txt-length))
         (message-box "Error"
                      "Buffer has changed since extract-function"
                      fr '(ok stop))]
        [else
         (define module-stx
           (with-handlers ([exn:fail:read?
                            (λ (e)
                              (message-box "Error"
                                           (string-append "Syntax error while reading file: "
                                                          (exn-message e))
                                           fr '(ok stop))
                              #f)])
             (module-string->syntax txt f)))
      
         (when module-stx

           (define module-scope (syntax-scope module-stx))
        
           (define to-pos (send ed get-start-position))

           ;; TODO: Prevent moving to a place where the definition is unreachable
           ;; from the call site.
           ;; We could check that the smallest enclosing scope of to-pos
           ;; also contains from-scope.
           ;; May fail with `begin`, but better to prevent some legal cases than
           ;; allow illegal ones? Or give a warning and the option?

           (define from-scope (scope start end))

           (define-values (in-unbounds out-unbounds)
             ; min with module-scope as the whitespaces at the end of the module
             ; are considered out of scope otherwise.
             (unbound-ids module-stx from-scope to-pos))
           ;; TODO: remove-duplicates is slow, also unbound-ids returns too many things?
           (define in-ids  (remove-duplicates (map first in-unbounds)))
           (define out-ids (remove-duplicates (map first out-unbounds)))

           (define from-string (send ed get-text start end))
           (define-values (call-site fun-site)
             (make-call+fun-sites from-string fun-name in-ids out-ids))

           (send ed begin-edit-sequence)
           (send ed delete start end)
           (send ed insert call-site start)
           (send ed tabify-selection start (+ start (string-length call-site)))
           
           (define new-pos (send ed get-start-position))
           (send ed insert fun-site)
           (send ed tabify-selection new-pos (+ new-pos (string-length fun-site)))
           (send ed end-edit-sequence))]))
    #f))

