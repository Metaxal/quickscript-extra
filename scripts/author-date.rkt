#lang racket/base
(require racket/date
         quickscript/script)

;;; 4 shortcuts to print the author [email] date [time] 
;;; Laurent Orseau <laurent orseau gmail com> -- 2012-04-19

; Replace by your own data:
(define auth "Laurent Orseau")
(define email "<laurent orseau gmail com>")

(define (date-iso [time? #f])
  (parameterize ([date-display-format 'iso-8601])
    (date->string (current-date) time?)))

(define (author [email? #f])
  (if email?
      (string-append auth " " email)
      auth))

(define (author-date-all [email? #f] [time? #f]) 
  (string-append (author email?) " -- " 
                 (date-iso time?)))

(define-script author-date
  #:label "Author &date"
  #:menu-path ("Author date")
  (λ(str)(author-date-all #f #f)))

(define-script author-date-time
  #:label "Author date &time"
  #:menu-path ("Author date")
  (λ(str)(author-date-all #f #t)))

(define-script author-email-date
  #:label "Author &email date"
  #:menu-path ("Author date")
  (λ(str)(author-date-all #t #f)))

(define-script author-email-date-time
  #:label "A&uthor email date time"
  #:menu-path ("Author date")
  (λ(str)(author-date-all #t #t)))

(define-script license-wtfpl
  #:label "&WTFPL"
  #:menu-path ("Author date")
  (λ(str)"License: WTFPL - http://www.wtfpl.net"))

(define-script license-mit
  #:label "&MIT License"
  #:menu-path ("Author date")
  (λ(str)"License: MIT - http://opensource.org/licenses/MIT"))
