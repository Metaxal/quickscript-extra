#lang racket/base
(require racket/class
         racket/list
         racket/format
         quickscript)

(script-help-string
 "Cyclic word completion using the words of the current file.")

;;; In the editor ed, removes the right-hand-side word part at the cursor position if any,
;;; and completes the left-hand-side word at the cursor position by the next possible
;;; rhs word in the text.
;;; The cursor position is not modified, therefore by calling this procedure repeatedly,
;;; it is possible to cycle among all the corresponding words.

(define non-word-str   "\"'`,;\r\n\t (){}[]")
(define non-word-chars (string->list non-word-str))
(define non-word-re    (regexp-quote non-word-str))

;; Returns the first position that is not a word-like symbol
;; dir is -1 (for left) or 1 (for right)
(define (word-pos ed pos dir)
  (define offset (if (= dir 1) 0 -1))
  (define last (if (= dir 1) 
                   (send ed last-position)
                   0))
  (or
   (for/or ([p (in-range pos last dir)])
     (define ch (send ed get-text (+ p offset) (+ 1 p offset)))
     (and ch
          (memq (first (string->list ch)) non-word-chars)
          p))
   last))

;; Returns the string for the left- or right-hand-side of pos, depending on if dir=-1 or dir=1.
(define (get-word ed pos dir)
  (let ([p (word-pos ed pos dir)])
    (if p 
        (send ed get-text (min p pos) (max p pos))
        "")))

(define-script dabbrev
  #:label "D&ynamic completion"
  #:menu-path ("Re&factor")
  #:shortcut #\t
  #:shortcut-prefix (ctl shift)
  (λ (s #:editor ed) 
    (define pos (send ed get-end-position)) 
    (define left  (get-word ed pos -1))
    (define right (get-word ed pos  1))
    (define txt (send ed get-text))
    (define matches
      (remove-duplicates
       (regexp-match* (pregexp (string-append "\\b" (regexp-quote left) 
                                              "[^" non-word-re "]*"))
                      txt)))
    (when matches
      (define mems (member (string-append left right) matches))
      (define str
        (if (and mems (not (empty? (rest mems))))
            (second mems)
            (first matches)))
      (when str
        (send ed begin-edit-sequence)
        (send ed delete pos (+ pos (string-length right)))
        (send ed insert
              (substring str (string-length left)))
        (send ed set-position pos)
        (send ed end-edit-sequence)))
    #f))
