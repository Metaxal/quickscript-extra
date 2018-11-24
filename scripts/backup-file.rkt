#lang racket/base

(require quickscript
         racket/path
         racket/format
         racket/date
         racket/file)

(script-help-string "Copies the current file in the 'backups' subdirectory with a time stamp")

(define backup-sub-dir "backups")

(define (date->my-format d)
  (string-append
   (~r (date-year d) #:min-width 4 #:pad-string "0")
   "-"
   (~r (date-month d) #:min-width 2 #:pad-string "0")
   "-"
   (~r (date-day d) #:min-width 2 #:pad-string "0")
   "--"
   (~r (date-hour d) #:min-width 2 #:pad-string "0")
   "-"
   (~r (date-minute d) #:min-width 2 #:pad-string "0")
   "-"
   (~r (date-second d) #:min-width 2 #:pad-string "0")))

(define-script backup-file
  #:label "Back&up current file"
  #:menu-path ("&Utils")
  #:output-to message-box
  (λ (selection #:file f)
    (when f
      (define dir (path-only f))
      (define filename (file-name-from-path f))
      (define backup-dir (build-path dir backup-sub-dir))
      (make-directory* backup-dir)
      (define date-str
        (date->my-format (current-date))
        ;; The iso format includes "T" for date/time separator, which is hard to read,
        ;; and ":" as another separator, which may behave badly in filenames on some OSes.        
        #;(parameterize ([date-display-format 'iso-8601])
            (date->string (current-date) #t)))
      (define backup-filename (string-append date-str "--" (path->string filename)))
      (define new-file (build-path backup-dir backup-filename))
      (copy-file f new-file)
      (string-append (path->string f)
                     "\nCopied to\n"
                     (path->string new-file)))))
