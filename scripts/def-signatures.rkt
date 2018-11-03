#lang racket/gui
(require (for-syntax racket/base)
         (prefix-in scrbl: scribble/reader)
         framework
         mrlib/close-icon
         quickscript
         racket/runtime-path
         setup/dirs ; for doc-dir 
         srfi/13)

(script-help-string
 "Displays the signature of the procedure under the cursor
(like DrRacket's blue box but works also when the file does not compile).")

;;;    ***************************************    ;;;
;;;    ***   On-Screen Signature Display   ***    ;;;
;;;    ***************************************    ;;;

;;; Laurent Orseau <laurent orseau gmail com> -- 2012-04-26

#| *** How it works ***

Like DrRacket blue boxes, but works also when program does not compile.
(Because it does not use lexical information, it is less accurate and can thus display
multiple choices.)

** Usage:

Put the cursor in the middle of a Racket function symbol, and
press the keyboard shortcut for this script, or launch it from the menu.
The signature of the function/form should appear in a frame, if it can find it.

To hide the frame, press the shortcut again.

The frame can be moved around by dragging it.

The default shortcut is suitable for my keyboard, but probably not for yours; 
change it as you see fit.


** Notes:

I could not figure how to use xref, so instead the script parses 
the .scrbl files in racket's scribblings directory.
Since this can take a few seconds, the generated dict is saved to a file,
so that the parsing is only done once (if you ever need to force reparsing, 
simply remove the file in the script subdirectory, it will regenerate it at the next call).

The script does not use syntax information, and in particular 
from where the bindings are imported.

Some scrbl files contain a #reader line that breaks `read-inside'.
For such cases, the file is loaded as a string, the offending #reader is removed
and the contents are read from the string again.
In case the file cannot be read anyway, it is skipped. (none as of today)

Not all definitions are parsed yet (e.g., no parameter), but the number should grow,
and not all information is reported (e.g., no contract for forms yet).

The code is a mess, and I did not bother much to make it better...

|#


#| TODO:
- the 'function' identifier from 'plot' is not parsed.
- get-text-from-user wrongly parsed for #:validate
- the X button is very large on MacOS X and does not close the frame
- curried procedures are not correctly recognized (e.g., in some framework's rkt files)
- display module of the signature
- use an editor instead of canvas?
- warning: a "signature" seems to have a special meaning in Racket
- instead of showing all definition forms, show only one and allow cycling with shortkey/mouse?
- when a function name is not found, propose a list of similar names (edition distance)
|#

#| Testing procedure:
1) Delete the index-defs.rktd file
2) Restart DrRacket (from console for debugging), type with-output-to-file, and exec the script
   The index should be automatically built.
3) Touch the def-signatures.rktd file, and exec the script.
   It should ask for rebuilding the index-file. Say no and exec the script again.
4) Like 3) but say yes.

|#

;;; Global variables that the user might want to change

(define debug? #f)
(define (set!-debug? d)
  (set! debug? d))

(define text-size 
  ; relative to the user's preferences:
  (let ([size (preferences:get 'framework:standard-style-list:font-size)])
    (- (cond [(number? size) size]
             [(vector? size) (vector-ref size 1)]
             [else 12])
       2)))

(define srfi-files
  '("srfi-13.html" 
    "srfi-14.html"
    ))

(define rkt-files
  (list
   (build-path (collection-path "framework") "main.rkt")
   (build-path (collection-path "framework") "preferences.rkt")
   ))


;===========================;
;=== Parsing scribblings ===;
;===========================;

; for format
(print-as-expression #f)
(print-reader-abbreviations #t)


(define (scribblings-path subdir)
  (collection-path "scribblings" subdir))
  ;(build-path (find-system-path 'collects-dir)
  ;            "scribblings" subdir))
  

;; Returns the s-exp containing all s-exp in the input stream
;; in: input-stream?
(define (read-scrbl in [file ""])
  (scrbl:read-inside in))
  ;(syntax->datum (scrbl:read-syntax-inside file in)))

(define (read-rkt file)
  (with-input-from-file file
    (λ () 
      (void (read-language)) ; don't care about the #lang line
      ; no need to reverse since we don't care about the top level order:
      (let loop ([l '()])
        (define s (scrbl:read))
        (if (eof-object? s)
            l
            (loop (cons s l)))))))
  

(define (add-dict-entry dic key l)
  (hash-set! dic key
             (cons l (hash-ref dic key '()))))

(read-accept-lang #t)
(read-accept-reader #t)

;; Loads all the defproc forms from a given file into the dictionary.
(define (index-defs dic file)
  (when debug? (printf "File ~a\n" file))
  (define all 
    (with-input-from-file file
      (λ () (read-scrbl (current-input-port) file))))
  (parse-list dic all))

;; takes a list of x-exprs, parses it, and add found form to the dictionary
(define (parse-list dic all)
  
  (define (add-entry key l)
    (add-dict-entry dic key l))

  (define (parse-class class-id subs)
    (for ([s subs])
      (match s
        [(list-rest 'defconstructor args text)
         (add-entry class-id (list 'defconstructor class-id args))]
        [(list-rest 'defmethod '#:mode mode (list-rest id args) cont-out text)
         (add-entry id (list 'defmethod class-id id args cont-out))]
        [(list-rest 'defmethod (list-rest id args) cont-out text)
         (add-entry id (list 'defmethod class-id id args cont-out))]
        [(list-rest 'defmethod* (list (list (list-rest ids argss) cont-outs) ...) text)
         (for ([id ids][args argss][cont-out cont-outs])
           (add-entry id (list 'defmethod class-id id args cont-out)))]
        [else #f])))
  
  (define (add-doc/names id cont-args args args+vals cont-out)
    (add-entry id (list 'defproc id 
                        (map (λ (a c) 
                               (if (and (list? c) (keyword? (first c)))
                                   ; with keyword:
                                   (list* (first c) (first a)
                                          (second c) (rest a))
                                   (list* (first a) c (rest a))))
                             (append (map list args) args+vals)
                             cont-args)
                        cont-out)))
  
  (define parse-cont-args
    (match-lambda
      [(list-rest (? keyword? k) c r)
       (cons (list k c) (parse-cont-args r))]
      [(list-rest c r)
       (cons c (parse-cont-args r))]
      [(list)
       '()]))
  
  (define (parse-doc subs)
    (for ([s subs])
      (match s
        [(list 'proc-doc/names id 
               (list '->* cont-args cont-opt-args cont-out)
               (list (list args ...) 
                     args+vals) 
               text)
         (add-doc/names id 
                        (append (parse-cont-args cont-args)
                                (parse-cont-args cont-opt-args))
                        args args+vals
                        cont-out)]
        [(list 'proc-doc/names id
               (list '-> cont-args ... cont-out)
               (list args ...) text)
         (add-doc/names id (parse-cont-args cont-args) args '() cont-out)]
        [(list 'proc-doc id cont text)
         (add-entry id (list 'thing-doc id cont))]
        [(list thing-doc id cont text)
         (add-entry id (list 'thing-doc id cont))]
        [else #f])))
  
  ; matches only the "top-level" forms, i.e. does not go into examples, etc.
  ; (hopefully there aren't many false positives/negatives)
  (define (parse-all subs)
    (for ([s subs])
      (match s
        [(list-rest 'defproc (list-rest name args) cont-out text)
         (add-entry name (list 'defproc name args cont-out))]
        [(list-rest 'defproc* (list (list (list-rest names argss) cont-outs) ...) text)
         (for ([name names] [args argss] [cont-out cont-outs])
           (add-entry name (list 'defproc name args cont-out)))]
        [(list-rest (or 'defclass 'defclass/title) id super intf-ids subs)
         (add-entry id (list 'defclass id super intf-ids))
         (parse-class id subs)]
        [(list-rest (or 'definterface 'definterface/title) id intf-ids subs)
         (add-entry id (list 'definterface id intf-ids))
         (parse-class id subs)]
        [(list-rest (or 'defform 'defform/subs) (list-rest id args) text) ; TODO: + contracts & literals + subs
         (add-entry id (list 'defform id args))]
        [(list-rest (or 'defform* 'defform*/subs) (list (list-rest ids argss) ...) text)
         (for ([id ids][args argss])
           (add-entry id (list 'defform id args)))]
        [(list-rest 'deftogether subs text)
         (parse-all subs)]
        [(list-rest 'provide/doc subs)
         (parse-doc subs)]
        ; provide/doc has been changed to just 'provide recently:
        ; http://lists.racket-lang.org/dev/archive/2012-May/009500.html
        ; (this might make the parsing significantly longer...)
        ; (unless I specifically tell which files do that?)
        ; (looks ok though)
        [(list-rest 'provide subs)
         (parse-doc subs)]
        [else #f]
        )))
  
  (parse-all all)
  )

(define replace-dict
  '(("&nbsp;"  . " ")
    ("&gt;"    . ">")
    ("&lt;"    . "<")
    ("&amp;"   . "&")
    ("<sub>"   . "")
    ("</sub>"  . "")
    ))

(define (html-string->string str)
  (for/fold ([str str]) ([(k v) (in-dict replace-dict)])
    (regexp-replace* (regexp-quote k) str (regexp-replace-quote v))))

(define (parse-srfi-file dic file)
  (define lines (file->lines file))
  (for ([line lines])
    (define l (regexp-match 
               (pregexp
                (string-append
                 "<code class=\"?proc-def\"?>"
                 "([^" (regexp-quote "([{}])\"'") "]*)"
                 ;"(.*)"
                 "</code>\\s*<var>"
                 "(.*)"
                 ;"(.*)"
                 "</var>"))
               line))
    (when l
      (let ([id-str (string-trim-both (html-string->string (second l)))])
        (add-dict-entry 
         dic
         (string->symbol id-str)
         (list 'srfi id-str (string-trim-both (html-string->string (third l)))))))))

;==========================;
;=== Creating the Index ===;
;==========================;

;; Displays a message in a (non-modal) frame.
(define (frame-message title message [show? #f] #:parent [parent #f])
  (define fr (new frame% [parent parent] [label title]))
  (new message% [parent fr] [label message])
  (when show? (send fr show #t))
  fr)

(define-runtime-path idx-file (build-path "def-index" "def-index.rktd"))
(make-directory* (path-only idx-file))

(define-syntax-rule (with-parse-handler file body ...)
  (with-handlers ([exn:fail? (λ _ (when debug?
                                    (printf "Warning: Could not parse file ~a~n" file)))])
    body ...))

;(define-runtime-path this-file "def-signatures.rkt")
(define-syntax (this-file stx)
   (with-syntax ([file (syntax-source stx)])
     #'file))

;; Constructs the index file if it does not exist, or load it,
;; and returns the generated index:
(define (create-index)
  
  (when (file-exists? idx-file)
    (if (and
         (> (file-or-directory-modify-seconds (this-file))
            (file-or-directory-modify-seconds idx-file))
         (eq? 'yes
              (message-box "Recreate doc"
                           "Script def-signatures:
The documentation index looks older than the script file.
Do you want to recreate the index?"
                           #f '(caution yes-no))))
        (delete-file idx-file)
        ; else touch the file to avoid asking  the question again:
        (file-or-directory-modify-seconds idx-file (current-seconds))
        ))
  
  (if (file-exists? idx-file)
      (with-input-from-file idx-file read)
      (let* ([dic (make-hash)]
             [fr (frame-message "Making index" "Constructing documentation index for the first time.\nPlease wait..." #t)]
             [read-scrbl-dir 
              (λ (dir) 
                (when (directory-exists? dir)
                  (for ([f (in-directory dir)])
                    (when (equal? (filename-extension f) #"scrbl")
                      (with-parse-handler f
                                          (index-defs dic f)
                                          )))))])
        
        ; read all scrbl files in all collections:
        (for-each read-scrbl-dir
                  (list (find-collects-dir)
                        (find-user-collects-dir)
                        (find-pkgs-dir)
                        (find-user-pkgs-dir)))
        
        (for ([f rkt-files])
          (with-parse-handler f
            (parse-list dic (read-rkt f))))
        
        ; constructing index for srfi files:
        (for ([f srfi-files])
          (let ([f (build-path (find-doc-dir) "srfi-std" f)])
            (with-parse-handler f
              (parse-srfi-file dic f))))
        
        (when debug? (printf "~a identifiers found\n" (dict-count dic)))

        ; write the generated dict to a file for speed up on next loadings:        
        (with-output-to-file idx-file
          (λ () (write dic)))
        
        (send fr show #f)
        dic)))

;=====================================;
;=== Formatting entries as strings ===;
;=====================================;

;; Helpers for def-name->string-list
(define (arg->head-string arg)
  (match arg
    [(list name cont)                      (symbol->string name)]
    [(list (? keyword? kw) name cont)      (format "~v ~v" kw name)]
    [(list name cont val)                  (format "[~v]" name)]
    [(list (? keyword? kw) name cont val)  (format "[~v ~v]" kw name)]
    ['...                                  "..."]
    ['...+                                 "...+"]
    ))

(define (arg->sig-string arg)
  (match arg
    [(list name cont)                      (format "  ~v: ~v" name cont)]
    [(list (? keyword? kw) name cont)      (format "  ~v: ~v" name cont)]
    [(list name cont val)                  (format "  ~v: ~v = ~v" name cont val)]
    [(list (? keyword? kw) name cont val)  (format "  ~v: ~v = ~v" name cont val)]
    ['...                                  #f]
    ['...+                                 #f]
    ))

(define NO_ENTRY_FOUND "No entry found")

;; Returns the list of signature in line-splitted string-format.
;; -> (list def-strings)
;; def-strings : (list string?)
(define (def-name->string-list dic name)
  (define entries (dict-ref dic name #f))
  (if entries
      (for/list ([entry entries])
        (match entry
          [(list 'defclass id super intf-ids)
           (list (format "~v : class?" id)
                 (format "  superclass: ~v" super)
                 (string-join (cons "  extends:" 
                                    (map symbol->string intf-ids))
                              " "))]
          [(list 'definterface id intf-ids)
           (list (format "~v : interface?" id)
                 (string-join (cons "  implements:"
                                    (map symbol->string intf-ids))
                              " "))]
          [(list 'defconstructor class-id args)
           (list* (string-append
                   (format "(new ~v " class-id)
                   (string-join (map arg->head-string args) " ")
                   ")")
                  (filter values (map arg->sig-string args)))]
          [(list 'defmethod class-id id args cont-out)
           (list*
            (string-append
             (format "(send a-~a ~a " class-id id)
             (string-join (map arg->head-string args) " ")
             ") -> "
             (format "~v" cont-out)
             )
            (filter values (map arg->sig-string args))
            )]
          [(list 'defproc id args cont-out)
           (list*
            (string-append
             "("
             (string-join (cons (symbol->string name)
                                (map arg->head-string args)) " ")
             ") -> "
             (format "~v" cont-out)
             )
            (filter values (map arg->sig-string args))
            )]
          [(list 'defform id args)
           (list (format "~v" (cons id args)))]
          [(list 'srfi id-str args)
           (list (string-append id-str " " args))]
          [(list 'doc-thing id cont)
           (list (format "~v : ~v" id cont))]
          [else (list (format "Unknown parsed form: ~a" entry))]
          ))
      `((,NO_ENTRY_FOUND))))

; The definition index. Since the script is persitent, it is loaded only once
(define def-index (create-index))

#| TESTS
(dict-ref def-index 'list)
(def-name->string-list def-index 'with-output-to-file)
(def-name->string-list def-index 'string-pad)

;|#

;===========;
;=== GUI ===;
;===========;

;;; In the following, a 'text' is a list of strings.

; The font to use for the text
(define label-font
  (send the-font-list find-or-create-font
        text-size
        'modern 'normal 'normal #f))

(define inset 2)

; Calculate the minimum sizes of a string
(define (calc-min-sizes dc str label-font)
  (send dc set-font label-font)
  (let-values ([(w h a d) (send dc get-text-extent str label-font)])
    (let ([ans-w (max 0 (inexact->exact (ceiling w)))]
          [ans-h (max 0 (inexact->exact (ceiling h)))])
      (values ans-w ans-h))))

;; Calculate the total size of a text, with inset
(define (dc-text-size dc text label-font)
  (define w-h
    (for/list ([str text])
      (let-values ([(w h) (calc-min-sizes dc str label-font)])
        (list w h))))
  (values
   (+ inset inset (apply max (map car  w-h)))
   (+ inset inset (apply +   (map cadr w-h)))))

;; Draws the text (list of strings) in dc at x y,
;; each string on below the other, left-aligned.
(define (draw-text dc x y text)

  (define black-color  (make-object color% "black"))
  (define bg-color     (make-object color% "wheat"))
    
  (define-values (w h)
    (dc-text-size dc text label-font))
  
  ; background square
  (send dc set-pen (send the-pen-list find-or-create-pen
                         bg-color 1 'solid))
  (send dc set-brush (send the-brush-list find-or-create-brush
                           bg-color 'solid))
  (send dc draw-rectangle x y w h)
  
  ; boundaries
  (send dc set-pen (send the-pen-list find-or-create-pen
                         black-color 1 'solid))
  (send dc draw-line x y (+ x w) y)
  (send dc draw-line (+ x w) y (+ x w) (+ y h))
  (send dc draw-line (+ x w) (+ y h) x (+ y h))
  (send dc draw-line x (+ y h) x y)
  
  ; draw text into the square
  ; set colors, fonts, etc.
  (send dc set-text-foreground black-color)
  (send dc set-text-background bg-color)
  (send dc set-font label-font)
  (define ytot
    (for/fold ([ytot (+ y inset)])
      ([str text])
      (let-values ([(w h) (calc-min-sizes dc str label-font)])
        (send dc draw-text str (+ x inset) ytot)
        (values (+ h ytot)))))
  ; return value:
  (values w h))

(define tooltip-frame%
  (class frame%
    (init-field [text '()])
    (super-new [label ""]
               [style '(no-resize-border 
                        no-caption
                        no-system-menu
                        hide-menu-bar
                        float)]
               ;[min-height 400]
               ;[min-width 400]
               [stretchable-width #f]
               [stretchable-height #f]
               )
    
    (define/override (on-subwindow-char e k)
      (when (equal? (send k get-key-code) 'escape)
        (send this show #f))
      #f)
    
    (define hp (new horizontal-panel% [parent this]
                    [alignment '(left top)]))
    
    (new close-icon% [parent hp]
         [callback (λ _ (send (this-frame) show #f))])
    
    (define (this-frame) this)
    
    ;; Internal canvas class
    (define tooltip-canvas%
      (class canvas%
        (define x-start #f)
        (define y-start #f)
        (define/override (on-event ev)
          (when (send ev get-left-down)
            (if (send ev moving?)
                (let ([x (send ev get-x)] [y (send ev get-y)])
                  (let-values ([(x y) (send this client->screen (round x) (round y))])
                    (send (this-frame) move (- x x-start) (- y y-start))))
                (begin (set! x-start (send ev get-x))
                       (set! y-start (send ev get-y))))))
        (super-new)
        ))
    
    (define cv (new tooltip-canvas% [parent hp]
                    [paint-callback 
                     (λ (cv dc) (draw-text dc 0 0 text))]))
    
    (define/public (set-text t)
      (set! text t)
      (define-values (w h) (dc-text-size (send cv get-dc) text label-font))
      (send cv min-width (+ w 1))
      (send cv min-height (+ h 1))
      (send this reflow-container)
      (send this stretchable-width #f)
      (send this stretchable-height #f)
      (send cv refresh))
    
    (unless (empty? text)
      (set-text text))
    ))

;::::::::::::::::;
;:: The script ::;
;::::::::::::::::;

(define (def-name->text sym)
  (define defs (def-name->string-list def-index sym))
  (append* (add-between defs '(""))))

;; persistent variables, to use always the same ones
(define tooltip-frame #f)
(define last-sym #f)

(define-script def-signatures
  #:label "Signature"
  #:shortcut #\$
  #:shortcut-prefix (ctl)
  #:persistent
  (λ (str #:editor ed) 
    (define start-pos (send ed get-start-position))
    (define end-pos   (send ed get-end-position)) 
    (define start-exp-pos
      (or (send ed get-backward-sexp start-pos) start-pos))
    (define end-exp-pos
      (or (send ed get-forward-sexp (- end-pos 1)) end-pos))
    (define str
      ;(send ed get-word-at (send ed get-forward-sexp (send ed get-start-position))))
      (send ed get-text start-exp-pos end-exp-pos))
  
    (define sym (string->symbol str))
    (define text (def-name->text sym))
  
    (define dc (send ed get-dc))
  
    (unless tooltip-frame
      (set! tooltip-frame (new tooltip-frame%)))
  
    ; if the new sym is the same as the old one, 
    ; or if it is an invalid one, hide the frame,
    ; otherwise show it for the new symbol.
    (if (and (eq? sym last-sym) (send tooltip-frame is-shown?))
        (send tooltip-frame show #f)
        (let ()
          (define &x (box #f))
          (define &y (box #f))
          (send ed position-location start-exp-pos &x &y #f #t)
          (define-values (x y) (send ed editor-location-to-dc-location 
                                     (unbox &x) (unbox &y)))
        
          (let-values ([(x y) (send (send ed get-canvas)
                                    client->screen (round (inexact->exact x)) (round (inexact->exact y)))]
                       [(left top) (get-display-left-top-inset)])
            (send tooltip-frame move (- x left) (- y -2 top))
            (send tooltip-frame set-text text)
            (send tooltip-frame show #t)
            (set! last-sym sym)
            )))
    #f))

; These tests are likely to fail within an automated tester if the docs are not installed, hence they are commented out.
#;
(module+ test
  (require rackunit)

  (set!-debug? #t)
  
  (define defs
    '(with-output-to-file list->string print error make-module-evaluator make-provide-transformer list->string open-input-output-file	 regexp-replace
    
       button% set-label class get-top-level-window min-height refresh on-move get-x get-cursor focus
       ; framework (complicated ones!):
       finder:common-put-file  preferences:set-default
       ))
  (for ([d (in-list defs)])
    (check-not-false (dict-ref def-index d #f)))
  )
