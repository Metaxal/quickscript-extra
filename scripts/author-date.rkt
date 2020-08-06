#lang racket/base
(require racket/date
         quickscript)

(script-help-string
 "Insert text snippets with author, date, time, and licence.")

;;; 4 shortcuts to print the author [email] date [time] 
;;; Laurent Orseau <laurent orseau gmail com> -- 2012-04-19

; Replace by your own data:
(define auth "Firstname Lastname")
(define email "<firstname.lastname@myemail.com>")

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
  #:menu-path ("&Author date")
  (λ (str) (author-date-all #f #f)))

(define-script author-date-time
  #:label "Author date &time"
  #:menu-path ("&Author date")
  (λ (str) (author-date-all #f #t)))

(define-script author-email-date
  #:label "Author &email date"
  #:menu-path ("&Author date")
  (λ (str) (author-date-all #t #f)))

(define-script author-email-date-time
  #:label "A&uthor email date time"
  #:menu-path ("&Author date")
  (λ (str) (author-date-all #t #t)))

(define-script license-cc-by4
  #:label "&CC-BY 4.0"
  #:menu-path ("&Author date")
  (λ (str) "License: [CC-BY 4.0](https://creativecommons.org/licenses/by/4.0/)"))

(define-script license-dual-mit-apache2
  #:label "Dual A&pache2.0/MIT License"
  #:menu-path ("&Author date")
  (λ (str)
    #<<EOS
License: [Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0) or
         [MIT license](http://opensource.org/licenses/MIT) at your option.
EOS
    ))

(define-script license-apache2
  #:label "&Apache 2.0"
  #:menu-path ("&Author date")
  (λ (str)
    "License: [Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0)"))

(define-script license-mit
  #:label "&MIT License"
  #:menu-path ("&Author date")
  (λ (str) "License: [MIT](http://opensource.org/licenses/MIT)"))
