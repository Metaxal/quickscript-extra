#lang racket/base
(require framework
         racket/class
         racket/contract
         racket/set
         racket/port
         racket/pretty
         racket/gui/base
         quickscript)

(script-help-string "Display information about the current color theme.")

(define-script show-theme
  #:label "Show color theme"
  #:menu-path ("&Utils")
  (λ (str) 
    (theme->frame)
    #f))

; Call (theme->frame) to open a frame with the current style as an info.rkt file

(color-prefs:register-info-based-color-schemes)

(define (obj->list o)
  (cond [(list? o)
         (map obj->list o)]
        [(is-a? o style-delta%)
         (style->list o)]
        [(is-a? o color%)
         (list (color->list o))]
        [(is-a? o add-color<%>)
         (vector (send o get-r) (send o get-g) (send o get-b))]
        [else o]))

(define (color->list c [alpha? #t])
  (vector (send c red)
          (send c green)
          (send c blue)
          #;(if alpha?
                (list (send c alpha))
                '())))

(define (style->list s)
  (map obj->list 
       (filter (not/c 'base)
               (list
                #;(send s get-alignment-off)
                #;(send s get-alignment-on)
                #;(send s get-background-add)
                #;(send s get-background-mult)
                #;(send s get-face)
                #;(send s get-family)
                (send s get-foreground-add)
                #;(send s get-foreground-mult)
                #;(send s get-size-add)
                #;(send s get-size-in-pixels-off)
                #;(send s get-size-in-pixels-on)
                #;(send s get-size-mult)
                #;(send s get-smoothing-off)
                #;(send s get-smoothing-on)
                #;(send s get-style-off)
                (send s get-style-on)
                #;(send s get-transparent-text-backing-off)
                #;(send s get-transparent-text-backing-on)
                #;(send s get-underlined-off)
                (if (send s get-underlined-on) 'underline 'base)
                #;(send s get-weight-off)
                (send s get-weight-on)
                ))))

(define (get-current-theme)
  (define-values
    (color-names style-names)
    (color-prefs:get-color-scheme-names))
  (set-union color-names style-names))

(define (theme->hash [theme (get-current-theme)])
  `#hash((name . "My color theme")
            (colors
             .
             ,(for/list ([key theme])
                (cons key (obj->list (color-prefs:lookup-in-color-scheme key)))))))

(define (theme->file-string [theme (get-current-theme)])
  (with-output-to-string
   (λ () (displayln "#lang info\n")
     (pretty-print
      `(define framework:color-schemes 
         '(,(theme->hash theme)))
      (current-output-port)
      1))))

;; Like frame:text% but without exiting the app when closing the window
(define no-exit-frame:text%
  (class frame:text%
    (super-new)
    (define/override (on-exit)
      (void))
    (define/override (can-exit?)
      #f)
    (define/augment (on-close)
      (void))
    (define/augment (can-close?)
      (send this show #f)
      #f)
    ))

(define (theme->frame [theme (get-current-theme)])
  (exit:set-exiting #f)
  (define f (new no-exit-frame:text%
                 [width 800]
                 [height 600]))
  (define ed (send f get-editor))
  (send ed insert (theme->file-string theme))
  (send f show #t))
