#lang racket
(require srfi/13
         quickscript/script)

(script-help-string "Indent rows on double-space-separated colums
(video: https://www.youtube.com/watch?v=KJjVREsgnvA).")

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

(define-script indent-table
  #:label "Table indent (on double-spaces)"
  #:menu-path ("Sele&ction")
  #:shortcut #\I
  #:shortcut-prefix (ctl shift)
  (λ(str)
    ; split in lines:
    (define lines 
      (regexp-split #rx"\n" str))
    ;(pretty-write lines)
    ; split in columns, after removing all leading and trailing spaces:
    (define llines2 
      (for/list ([l lines])
        (regexp-split #px"\\s\\s+" (string-trim-both l))))
    ; pad too short lists with empty columns:
    (define llines3
      (let ([lmax (apply max (map length llines2))])
        (map (λ(ll)(append ll (build-list (- lmax (length ll)) (λ _ ""))))
             llines2)))
    ; re-prepend the leading spaces to preserve indentation:
    (define llines
      (map (λ(ll l)(cons (string-append (first (regexp-match #px"^\\s*" l)) (first ll))
                         (rest ll)))
           llines3 lines))
    ;(pretty-write llines)
    ; pad each item in each column to the length of the longest item in the column:
    (define lcols (apply map (λ items (let ([lmax (apply max (map string-length items))])
                                        (map (λ(s)(string-pad-right s (+ 2 lmax))) items)))
                         llines))
    ;(pretty-write lcols)
    ; make the string for each line, and remove trailing spaces (last column has also been resized):
    (define indented-lines 
      (apply map (λ items (string-trim-right (apply string-append items)))
             lcols))
    ; append all the lines:
    (define str-new
      (string-join indented-lines "\n"))
    ; return value:
    str-new
    ))
  

(module+ drracket
  (display
   (indent-table "
    a  b  c    
   aa    bb  cc  dd  ee
 aaaa  bbb    ccccc  dddd
    x             y  z  
"))
  (newline)

  (display
   (indent-table "(let ([xxx  (make me a  sandwich)]
      [yy  (make me an  apple-pie)]
      [zzzzz  43])"))
  (displayln " ; THIS SHOULD NOT BE ON ITS OWN LINE")
  (newline)
  (display
   (indent-table "(define something      5)
(define some-other-thing  '(let me know))
")))

