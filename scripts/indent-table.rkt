#lang racket
(require (only-in srfi/13 string-pad-right)
         racket/gui/base
         quickscript)

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
  (define llines2 
    (for/list ([l lines])
      (regexp-split px-splitter (string-trim l))))
  ; pad too short lists with empty columns:
  (define llines3
    (let ([lmax (apply max (map length llines2))])
      (map (λ (ll) (append ll (build-list (- lmax (length ll)) (λ _ ""))))
           llines2)))
  ; re-prepend the leading spaces to preserve indentation:
  (define llines
    (map (λ (ll l) (cons (string-append (first (regexp-match #px"^ *" l)) (first ll))
                       (rest ll)))
         llines3 lines))
  ;(pretty-write llines)
  ; pad each item in each column to the length of the longest item in the column:
  (define lcols (apply map (λ items (let ([lmax (apply max (map string-length items))])
                                      (map (λ (s) (string-pad-right s lmax)) items)))
                       llines))
  ;(pretty-write lcols)
  ; make the string for each line, and remove trailing spaces (last column has also been resized):
  (define indented-lines 
    (apply map (λ items (string-trim (string-join items new-sep) #:left? #f))
           lcols))
  ; append all the lines:
  (define str-new
    (string-join indented-lines "\n"))
  ; return value:
  str-new
  )

(define-script indent-table
  #:label "Table indent (on double spaces)"
  #:menu-path ("Sele&ction")
  #:shortcut #\I
  #:shortcut-prefix (ctl shift)
  (λ (str) 
    (indent-table* str)))

(define-script indent-table/gui
  #:label "Table indent (&gui)"
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

