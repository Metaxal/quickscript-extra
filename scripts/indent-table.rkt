#lang racket
(require (only-in srfi/13 string-pad-right)
         racket/gui/base
         quickscript)

(provide indent-table*)

(script-help-string "Indent rows on double-space-separated columns
[video](https://www.youtube.com/watch?v=KJjVREsgnvA)")

#|
Laurent Orseau <laurent orseau gmail com> -- 2012-04-19

This script indents elements as in a left-aligned table.
Left indentation is preserved.
The column separator is the double-space (in fact a space longer than 1).

For example (note the double-spaces):

  (let ([some-value  '(some list of things)]
        [some-othe-value  2]
        [finally-some-value-again  '(a list of items)])

Select the 3 lines, and apply the script.
This will reformat as follows:

  (let ([some-value                '(some list of things)]
        [some-othe-value           2]
        [finally-some-value-again  '(a list of items)])

In case the number of columns does not match on each line,
empty columns are added at the end of the shortest rows.

|#

(define (indent-table* str
                       #:sep [sep "  "] ; default separator: double space, which is innocuous for code (except python-like code)
                       #:new-sep [new-sep sep])
  ; split in lines, but don't remove empty lines:
  (define lines
    #;(regexp-split "\n" str)
    (string-split str "\n" #:trim? #f))
  ;(pretty-write lines)
  (define px-splitter
    (pregexp (string-append " *" (regexp-quote sep) " *")))
  ; split in columns, after removing all leading and trailing spaces:
  ; lens are the maximum lengths of the columns
  (define-values (llines2 lens)
    (for/fold ([llines2 '()]
               [rev-lens '()]
               #:result (values (reverse llines2) (reverse rev-lens)))
              ([l (in-list lines)])
      (define items (regexp-split px-splitter (string-trim l)))
      (if (equal? items '(""))
        ; Whitespace line, return an empty line
        (values (cons '() llines2) rev-lens)
        ; Re-prepend the leading spaces to the first item to preserve indentation.
        ; items cannot be empty.
        (let ([items (cons (string-append (first (regexp-match #px"^ *" l)) (first items))
                           (rest items))])
          #;(pretty-print items)
      
          (define diff-n-items (- (length items) (length rev-lens)))
          (define new-rev-lens
            (map max
                 (append (make-list (max 0 diff-n-items) 0)
                         rev-lens)
                 (append (make-list (max 0 (- diff-n-items)) 0)
                         (reverse (map string-length items)))))
          (values (cons items llines2)
                  new-rev-lens)))))

  (string-join
   (for/list ([items (in-list llines2)])
     (string-trim
      (string-join
       (for/list ([item (in-list items)]
                  [len (in-list lens)])
         (string-pad-right item len))
       new-sep)
      #:left? #f))
   "\n"))

(define-script indent-table
  #:label "Table indent (on double spaces)"
  #:menu-path ("Sele&ction")
  #:shortcut #\I
  #:shortcut-prefix (ctl shift)
  (λ (str) 
    (indent-table* str)))

(define-script indent-table/gui
  #:label "Table indent… (&gui)"
  #:menu-path ("Sele&ction")
  (λ (str) 
    (define sep (get-text-from-user "Table Indent" "Separator:"))
    (when (and sep (non-empty-string? sep))
      (indent-table* str #:sep sep))))
  

(module+ drracket
  (define table1
    "
    a  b  c    
   aa    bb  cc  dd  ee

 aaaa  bbb    ccccc  dddd
    x             y  z  
")
  (define table2
    "(let ([xxx  (make me a  sandwich)]
      [yy  (make me an  apple-pie)]
      [zzzzz  43])")
  (define table3
    "(define something      5)
(define some-other-thing  '(let me know))
")
  (display (indent-table* table1))
  (newline)
  (display (indent-table* table2))
  (displayln " ; THIS SHOULD NOT BE ON ITS OWN LINE")
  (newline)
  (display (indent-table* table3))
  (newline)
  (define table1b (indent-table* table1 #:new-sep " & "))
  (displayln table1b)
  (newline)
  (displayln (indent-table* table1b #:sep "&" #:new-sep "|"))
  )

(module+ test
  (require rackunit)
  (let ()
    (define from "\
  (define immutable-string (string->immutable-string string))
  (define start (string-replacement-start replacement))
  (define end (string-replacement-original-end replacement))
  (define new-end (string-replacement-new-end replacement))
  (define contents (string-replacement-contents replacement))
  (define required-length (string-replacement-required-length replacement))
  (define original-length (string-length immutable-string))
")
    (define to "\
  (define immutable-string (string->immutable-string string))
  (define start            (string-replacement-start           replacement))
  (define end              (string-replacement-original-end    replacement))
  (define new-end          (string-replacement-new-end         replacement))
  (define contents         (string-replacement-contents        replacement))
  (define required-length  (string-replacement-required-length replacement))
  (define original-length  (string-length immutable-string))
")
    (define str2 (indent-table* from #:sep " ("))
    (define str3 (indent-table* str2 #:sep " rep"))

    #;(displayln str3)
    (check-equal? str3 to))

  (let ()
    (define from "\
  [union-into-string-replacement (reducer/c string-replacement? string-replacement?)]
  [string-replacement-render (-> string-replacement? string? immutable-string?)]
  [string-apply-replacement (-> string? string-replacement? immutable-string?)]
  [file-apply-string-replacement! (-> path-string? string-replacement? void?)]
  [inserted-string? predicate/c]
  [inserted-string (-> string? inserted-string?)]
  [inserted-string-contents (-> inserted-string? immutable-string?)]
  [copied-string? predicate/c]
")
    (define to
      "\
  [union-into-string-replacement  (reducer/c   string-replacement? string-replacement?)]
  [string-replacement-render      (->          string-replacement? string?               immutable-string?)]
  [string-apply-replacement       (->          string?             string-replacement?   immutable-string?)]
  [file-apply-string-replacement! (->          path-string?        string-replacement?   void?)]
  [inserted-string?               predicate/c]
  [inserted-string                (->          string?             inserted-string?)]
  [inserted-string-contents       (->          inserted-string?    immutable-string?)]
  [copied-string?                 predicate/c]
")
    (define str2 (indent-table* from #:sep " "))
    #;(displayln str2)
    (check-equal? str2 to))

  
  )

