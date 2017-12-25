#lang racket/gui
(require quickscript/script)

#|
Bookmarks are "anchors" as comments in the source code, and thus are part of the file
(but they are very little invasive and can be used, for example, as section headers).

Each time the user uses "Go to line" or "Save line number" or uses a bookmark,
the current line position is saved.
The user can use "Go to previous line" to go back to the latest saved position.
The full history is saved, so the user can get back like in an undo list.

|#

(define saved-lines (make-hash))

#;
(define-script view-hash
  #:label "view hash"
  #:menu-path ("Bookmarks")
  #:persistent
  (λ(str)
    (message-box "save-current-line!" (~a saved-lines))
    #f))

;; Saves the current line to be used with goto-previous
(define-script temp-bookmark
  #:label "Save line number"
  #:menu-path ("Bookmarks")
  #:persistent
  (λ(str #:editor ed)
    (save-current-line! ed)
    #f))

;; Saves the current line, and asks for the line to go to
(define-script goto-line
  #:label "Go to line..."
  #:menu-path ("Bookmarks")
  #:shortcut f9
  #:shortcut-prefix (shift)
  #:persistent
  (λ(str #:editor ed) 
    (define line (get-text-from-user "Go to line" "Line number:"
                                     #:validate string->number))
    (define lnum (and line (string->number line)))
    (when lnum
      (save-current-line! ed)
      (ed-goto-line ed (sub1 lnum)))
    #f))

;; Goes to the previous saved location 
(define-script goto-previous
  #:label "Go to previous line number"
  #:menu-path ("Bookmarks")
  #:shortcut f9
  #:shortcut-prefix (ctl shift)
  #:persistent
  (λ(str #:editor ed)
    (define ln (pop-saved-line! ed))
    (when ln 
      (ed-goto-line ed ln))
    #f))
    
;; Shows the list of bookmarks
(define-script bookmarks
  #:label "Bookmarks"
  #:menu-path ("Bookmarks")
  #:shortcut f9
  #:shortcut-prefix ()
  #:persistent
  (λ(str #:definitions ed) 
    (bookmark-frame (get-marks ed) ed)
    #f))

(define (get-marks ed)
  (define txt (send ed get-text))
  (filter values
          (for/list ([line (in-lines (open-input-string txt))]
                     [i (in-naturals)])
            ; To be usable with section headers:
            (define m (or (regexp-match #px";(?:@@*|==*|::*)\\s*(.*[\\w-].*?)[@=:;]*" line)
                          (regexp-match #px"#:title \"(.*)\"" line))) ; for slideshow
            (and m (list i (second m))))))

;; Adds a bookmark on the current line
(define-script add-bookmark
  #:label "Add bookmark"
  #:menu-path ("Bookmarks")
  #:shortcut f9
  #:shortcut-prefix (ctl)
  (λ(str)
    (string-append ";@@ " (if (string=? str "") 
                              (format "bookmark name")
                              str))))

;@@ Here and now


(define (save-current-line! ed)
  (define ln (send ed position-paragraph (send ed get-start-position)))
  (hash-update! saved-lines ed (λ(l)(cons ln l)) '()))

(define (pop-saved-line! ed)
  (define lines (hash-ref! saved-lines ed '()))
  (if (empty? lines)
      #f
      (begin0 (first lines)
              (hash-set! saved-lines ed (rest lines)))))
         
(define (ed-goto-line ed ln)
  (define l-start (box #f))
  (define l-end (box #f))
  (send ed get-visible-line-range l-start l-end)
  (send ed set-position (send ed paragraph-start-position ln))
  (send ed scroll-to-position (send ed paragraph-start-position (- ln  5)))
  (send ed scroll-to-position (send ed paragraph-start-position
                                    (+ ln (- (unbox l-end) (unbox l-start) 5)))))

(define (bookmark-frame marks ed)
  (define topwin (send ed get-top-level-window))
  (define fr (new frame% [parent #f]
                  [label "Bookmarks"]
                  [min-width 300] [min-height 300]))
  (define msg (new message% [parent fr] [label "Press <space> to select"]))
  (define (list-box-select lb)
    (define sel (send lb get-selection))
    (when sel
      (save-current-line! ed)
      (ed-goto-line ed (first (list-ref marks sel))))
    (when (send cb get-value)
      (send fr show #f)))
  (define (refresh-marks lb)
    (set! marks (get-marks ed))
    (send lb set (map second marks)))
  (define lb (new list-box% [label #f]
                  [parent fr]
                  [choices (map second marks)] ; show line number too?
                  [callback (λ(lb ev)
                              (print (send ev get-event-type))
                              (when (eq? (send ev get-event-type) 'list-box-dclick)
                                (list-box-select lb)))]
                  ))
  (define hp (new horizontal-panel% [parent fr] [alignment '(center center)] [stretchable-height #f]))
  (define bt-refresh (new button% [parent hp] [label "Refresh"] [callback (λ _ (refresh-marks lb))]))
  (define cb (new check-box% [parent hp] [label "Close on select?"] [value #t]))
  (define bt (new button% [parent fr] [label "Go!"] [callback (λ _ (list-box-select lb))]))
  ; Center frame on parent frame
  (send fr reflow-container) ;@@ Another bookmark
  (send fr move (+ (send topwin get-x) (round (/ (- (send topwin get-width) (send fr get-width)) 2)))
        (+ (send topwin get-y) (round (/ (- (send topwin get-height) (send fr get-height)) 2))) )
  (send lb focus)
  (send fr show #t))
