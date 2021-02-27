#lang racket/base

(require quickscript
         racket/format
         racket/class
         racket/path
         racket/gui/base)

(script-help-string
 "Extracts a block of code out of its context and generates a function and a call
 [video](https://www.youtube.com/watch?v=XinMxDLZ7Zw)")

;;;; How to use:
;;;; . Select a block of code
;;;; . Click on Scripts | extract-function (Ctrl-Shift-X)
;;;; . Enter a function name
;;;; . Move the cursor to the insertion point (don't edit the file!)
;;;; . Click on Scripts | put-function (Ctrl-Shift-Y)

;;;; This scripts aims at transforming the code while retaining its semantics, but
;;;; this is not perfect.
;;;; Some caveats:
;;;; . Don't trust this script too much, obviously. Check that the resulting code
;;;;   suits you.
;;;; . If check-syntax doesn't have all the information, the resulting code
;;;;   may not be semanticaly equivalent to the original.
;;;; . True lexical scoping via check-syntax is used for the original code,
;;;;   but only estimated for the code after transformation: An identifier is
;;;;   assumed to be in-scope if it is within the smallest common sexp of
;;;;   its definition (see `smallest-common-scope`).
;;;;   . This means that some identifiers may be considered out-of-scope when
;;;;     they are not.
;;;; . Mutated variables can lead to inconsistent results, hence a warning
;;;;   message is displayed for such cases.
;;;; . Currently the call site isn't checked to be in scope of the definition site.


;;; TODO: use `free-vars`:
;;; https://docs.racket-lang.org/syntax/syntax-helpers.html?q=free-vars#%28mod-path._syntax%2Ffree-vars%29
;;; This way we may avoid using check-syntax altogether!


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
;; The only function that uses check-syntax (show-content).
;; We keep the last results to avoid recomputing them, but we don't use a memo hash to avoid
;; linear increase of memory.
;; TODO: implement annotation-mixin instead of calling show-content.
(define syntax->source+mutation-dicts
  (let ([source-dict   #f]
        [mutation-dict #f]
        [module-stx    #f])
    (λ (mod-stx)
      (unless (eq? module-stx mod-stx)
        (define hsource (make-hash))
        (define hmutation (make-hash))
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
             (hash-set! hsource start-scope start-scope)
             (hash-set! hsource (scope end-left end-right) start-scope)]
            [(vector 'syncheck:add-mouse-over-status start end "mutated variable")
             (hash-set! hmutation (scope start end) #t)]
            [else (void)]))
        (set! source-dict hsource)
        (set! mutation-dict hmutation)
        (set! module-stx mod-stx))
      (values source-dict mutation-dict))))

;; Returns two lists:
;; The list of ids that are bound in from-scope but won't be bound in dest-pos,
;; and the list of ids outside of from-scope that are defined in from-scope
;; but will be undefined after moving the code to dest-pos.
;; Each list is made of an id an whether it is mutated.
(define (unbound-ids mod-stx from-scope dest-pos)
  ;; if dest-pos is after the scope of the module, 
  (set! dest-pos dest-pos)
  (define-values (source-dict mutation-dict)
    (syntax->source+mutation-dicts mod-stx))
  (define sym+scopes (id-scopes mod-stx))
  (define to-scope (smallest-common-scope mod-stx dest-pos))
  ;; ids in from-scope that will become unbound at dest-pos
  (define ins '())
  ;; ids outside of from-scope that will become unbound once
  ;; the code is moved to dest-pos
  (define outs '())
  (for ([s (in-list sym+scopes)])
    (define sym (first s))
    (define sym-scope (second s))
    (define sym-start (scope-start sym-scope))
    (define src (dict-ref source-dict sym-scope #f))
    (when (and (in-scope? sym-start from-scope)
               (and src
                    (not (in-scope? (scope-start src) from-scope))
                    (let ([sym-def-scope (smallest-common-scope mod-stx sym-start (scope-start src))])
                      (not (in-scope? dest-pos sym-def-scope #:strict? #t)))))
      (define entry (list sym (dict-ref mutation-dict src #f)))
      (unless (member entry ins)
        (set! ins (cons entry ins))))
    (when (and (not (in-scope? sym-start from-scope))
               (and src
                    (in-scope? (scope-start src) from-scope)))
      (define entry (list sym (dict-ref mutation-dict src #f)))
      (unless (member entry outs)
        (set! outs (cons entry outs)))))
  (values (reverse ins)
          (reverse outs)))

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

;; TODO: When require local file "file.rkt", it thinks it's in the wrong dir
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
  (define test-prog
    (match-lambda*
      [(list txt
             (list from-scopes common-from-scopes
                   dest-posss
                   expected-inss expected-outss)
             ...)
       (define stx (module-string->syntax txt))
       (define sym+scopes (id-scopes stx))
       (define-values (source-dict mutation-dict)
         (syntax->source+mutation-dicts stx))
       (let ([scopes-from-syncheck (map second sym+scopes)])
         ; This doesn't pass anymore because syncheck now binds arrows
         ; to the invisible #%app
         #;(for ([(k v) (in-dict source-dict)])
           (check member k scopes-from-syncheck (list k v))
           (check member v scopes-from-syncheck))
         (for ([from-scope         (in-list from-scopes)]
               [common-from-scope  (in-list common-from-scopes)]
               [expected-ins       (in-list expected-inss)]
               [expected-outs      (in-list expected-outss)]
               [dest-poss          (in-list dest-posss)])
           (define info1
             (format "from-scope: ~a common-from-scope:~a"
                     from-scope
                     common-from-scope))
           (when common-from-scope
             (check-equal? (smallest-common-scope stx from-scope)
                           common-from-scope
                           info1))
           (for ([dest-pos (in-list dest-poss)])
             (define-values (in-ids out-ids)
               (unbound-ids stx from-scope dest-pos))
             (define info2
               (format "~a dest-pos: ~a" info1 dest-pos))
             (check-equal? in-ids  expected-ins info2)
             (check-equal? out-ids expected-outs info2))))]))

  
  (test-prog
     "#lang racket

(define a 1)

(let ([e 4])
  (define b (+ e 1))
  (define c (+ a 3))
  (displayln b)
  (define d 4)
  (+ b c d))

"
     (list (scope 41 99) ; from-scope
           (scope 28 126) ; common-from-scope
           '(13 26 126 128) ; dest-pos
           '([e #f]) '([b #f] [c #f])) ; expected-ins expected-outs, #f = not mutated
     (list (scope 41 99)
           (scope 28 126)
           '(28)
           '([e #f]) '([b #f] [c #f]))
     (list (scope 41 99)
           (scope 28 126)
           '(40)
           '() '([b #f] [c #f])))

  (test-prog
   "#lang racket

(λ (abc)
  (+ abc 3))



"
   (list (scope 25 34)
         (scope 25 34)
         '(13 35)
         '([abc #f]) '()))

  ; Failure case: the mutated variable is moved, changing the semantics of the program.
  
  (test-prog
   "#lang racket

(let ([a 4])
  (set! a 2)
  a)
"
   (list (scope 29 39)
         (scope 29 39)
         '(13)
         '([a #t]) '()))
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
(define txt-length #f) ; Can we use a string-hash instead?
(define module-stx #f)
(define fil #f)
(define check-syntax-thread #f)

(define (start-cs-thread fil fr txt)
  (set! module-stx #f)
  (set! check-syntax-thread
        (thread
         (λ ()
           ;; Setting the current-directory to that of f;
           ;; ensures that read-syntax and syncheck have access to
           ;; local requires.
           (parameterize ([current-directory (if fil
                                               (path-only fil)
                                               (current-directory))])
             (define mod-stx
               (with-handlers ([exn:fail:read?
                                (λ (e)
                                  (string-append "Syntax error while reading file: "
                                                 (exn-message e)))])
                 (module-string->syntax txt fil)))
             ; Trigger show-content, which is what takes the most time.
             (syntax->source+mutation-dicts mod-stx)
             ; When module-stx is set, we are ready.
             (set! module-stx mod-stx))))))


(define-script extract-function
  #:label "extract-function"
  #:menu-path ("Re&factor")
  #:shortcut #\x
  #:shortcut-prefix (ctl shift)
  #:persistent
  (λ (selection #:file f #:editor ed #:frame fr)
    ; Start check-syntax early to be (more) ready on put-function
    (define txt (send ed get-text))
    (start-cs-thread f fr txt)
    (define name (get-text-from-user "Function name"
                                     "Choose a name for the new function"
                                     fr
                                     "FOO"
                                     '(disallow-invalid)
                                     #:validate (λ (s) (not (regexp-match #px"\\s|^#|\"|'" s)))))
    (cond
      [name
       (set! fun-name name)
       (set! start (send ed get-start-position))
       (set! end (send ed get-end-position))
       (set! fil f)
       (set! txt-length (string-length txt))]
      [else
       (kill-thread check-syntax-thread)
       (set! check-syntax-thread #f)])
    #f))

(define-script put-function
  #:label "put-function"
  #:menu-path ("Re&factor")
  #:shortcut #\y
  #:shortcut-prefix (ctl shift)
  #:persistent
  (λ (selection #:file f #:editor ed #:frame fr)
    ;; If module-stx, then the thread is irrelevant.
    ;; If not, then wait for the thread to produce module-stx.
    (when (or module-stx
              check-syntax-thread)
      (unless module-stx
        (thread-wait check-syntax-thread))
      (set! check-syntax-thread #f)
      (define txt (send ed get-text))
      (cond
        [(not (equal? fil f))
         (message-box "extract-function: File error"
                      "Cannot extract function to a different file"
                      fr '(ok stop))]
        [(not (= (string-length txt) txt-length))
         (message-box "extract-function: Buffer error"
                      "Buffer has changed since extract-function"
                      fr '(ok stop))]
        [(string? module-stx)
         (message-box "extract-function: Check-syntax error"
                      module-stx
                      fr '(ok stop))]
        [(not (syntax? module-stx))
         (message-box "extract-function: Error"
                      (format "Not syntax: ~a" module-stx)
                      fr '(ok stop))]
        [else
         ;; Setting the current-directory to that of f
         ;; ensures that read-syntax and syncheck have access to
         ;; local requires.
         (parameterize ([current-directory (if f
                                             (path-only f)
                                             (current-directory))])    

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

           (define mutated-ids (filter-map (λ (i) (and (second i) (first i))) in-unbounds))
           (define ok-mutation?
             (or (empty? mutated-ids)
                 (eq? 'yes
                      (message-box "Mutated variable"
                                   (format "The following variables are mutated:
~a

This may result in incorrect code.

Do you want to continue?"
                                           (apply ~a mutated-ids #:separator "\n"))
                                   fr
                                   '(yes-no caution)))))
           (when ok-mutation?
             
             ;; TODO: remove-duplicates is slow, also unbound-ids returns too many things?
             (define in-ids  (map first in-unbounds))
             (define out-ids (map first out-unbounds))

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
             (send ed end-edit-sequence)))]))
    #f))

