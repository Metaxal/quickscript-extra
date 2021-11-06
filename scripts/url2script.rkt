#lang racket/base

;;; License: [Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0) or
;;;          [MIT license](http://opensource.org/licenses/MIT) at your option.

(require quickscript
         quickscript/base
         quickscript/utils
         racket/class
         racket/file
         racket/match
         racket/port
         racket/path
         racket/string
         racket/gui/base
         net/url
         browser/external)

(script-help-string "Fetches a quickscript at a given url and adds it to the library.")

(define dir user-script-dir)

(define url2script-submod-name 'url2script-info)

(define (parse-url str)
  ; Do not keep trailing anchors
  (set! str (regexp-replace #px"[#?].*" str ""))
  (match str
    ; We can extract the filename
    ; "https://gist.githubusercontent.com/Metaxal/4449e/raw/342e26/letterfall.rkt"
    [(regexp #px"^https://gist\\.github(?:usercontent|)\\.com/[^/]+/[0-9a-f]+/raw/[0-9a-f]+/([^/]+)$"
                 (list _ filename))
     (values str filename)]
    ; "https://gist.githubusercontent.com/Metaxal/4449e059959da9f344f83c7e628ad9af/raw"
    ; "https://pastebin.com/raw/EMfcc5zs"
    [(or (regexp #px"^https://gist\\.github(?:usercontent|).com/[^/]+/[0-9a-f]+/raw$")
         (regexp #px"^https://gitlab\\.com/snippets/[0-9]+/raw$")
         (regexp #px"^http://pasterack\\.org/pastes/[0-9]+/raw$")
         (regexp #px"^https://pastebin.com/raw/[0-9a-zA-Z]+$"))
     (values str #f)]
    ; "https://gist.githubusercontent.com/Metaxal/4449e059959da9f344f83c7e628ad9af"
    ; "https://gitlab.com/snippets/1997854"
    ; "http://pasterack.org/pastes/8953"
    [(or (regexp #px"^https://gist\\.github(?:usercontent|)\\.com/[^/]+/[0-9a-f]+$")
         (regexp #px"^https://gitlab\\.com/snippets/[0-9]+$")
         (regexp #px"^http://pasterack\\.org/pastes/[0-9]+$"))
     (values (string-append str "/raw") #f)]
    ; "https://pastebin.com/EMfcc5zs"
    [(regexp #px"^https://pastebin.com/([0-9a-zA-Z]+)$" (list _ name))
     (values (string-append "https://pastebin.com/raw/" name) #f)]
    ; Any other kind of url, we assume a link to a raw file
    [else (values str #f)]))

;; TODO: check it is indeed a (valid?) quickscript
;; TODO: get-pure-port also handles files. This could be useful.
;; To prevent CDN caching, add "?cachebust=<some-random-number>" at the end of the url
;; (or "&cachebust=..."), just to make sure the url is different.
(define (get-text-at-url aurl)
  (port->string (get-pure-port (string->url aurl)
                               #:redirections 10)
                #:close? #t))

;; Notice: Does not ask to replace (should be done prior).
;; Doesn't add a submodule if one already exists.
;; Allows the designer to give the default file name to save the script.
(define (write-script fout text aurl #:filename [filename (file-name-from-path fout)])

  (display-to-file text fout #:exists 'replace)
  
  (unless (has-submod? fout)
    (display-to-file
     #:exists 'append
     (string-append
      "\n"
      "(module " (symbol->string url2script-submod-name) " racket/base\n" 
      "  (provide filename url)\n"
      "  (define filename " (format "~s" (and filename (path->string filename))) ")\n"
      "  (define url " (format "~s" aurl) "))\n")
     fout)))

;; Don't allow file or network access in the url2script submodule,
;; in particular because this module is `require`d right after downloading,
;; before the user has a chance to look at the file.
;; This prevents write and execute access, including calls to `system` and
;; `process` and friends.
(define dynreq-security-guard
  (make-security-guard (current-security-guard)
                       (λ (sym pth access)
                         (unless (or (equal? access '(exists))
                                     (equal? access '(read)))
                           (error (format "File access disabled ~a" (list sym pth access)))))
                       (λ _ (error "Network access disabled"))))

;; Get information from the url2script submodule.
(define (get-submod f sym [fail-thunk (λ () #f)])
  (parameterize ([current-security-guard dynreq-security-guard]
                 [current-namespace (make-base-empty-namespace)]
                 [current-environment-variables
                  ; prevent writing to (actual) environment variables
                  (environment-variables-copy (current-environment-variables))])
    (dynamic-require `(submod (file ,(path->string f)) ,url2script-submod-name)
                     sym
                     fail-thunk)))

;; Does the file contain a url2script submodule?
(define (has-submod? f)
  (with-handlers ([(λ (e) (and (exn:fail? e)
                               (string-prefix? (exn-message e) "instantiate: unknown module")))
                   (λ (e) #f)])
    (get-submod f (void))
    #t))

;====================;
;=== Quickscripts ===;
;====================;

(define-script url2script
  #:label "Fetch script…"
  #:help-string "Asks for a URL and fetches the script"
  #:menu-path ("url2script")
  (λ (selection #:frame frame)
    (define str (get-text-from-user
                 "url2script"
                 (string-append
                  "IMPORTANT:\nMake sure you trust the script before clicking on OK, "
                  "It may run automatically.\n\n"
                  "Enter a URL to gist, gitlab snippet or pasterack, or to a raw racket file:")))
    (when str
      ; At a special commit, with the name at the end, which we could extract.
      (define-values (aurl maybe-filename) (parse-url str))
      
      (define text (get-text-at-url aurl))
      (define ftmp (make-temporary-file))
      ; Write a first time to maybe-write and read the submod infos
      (write-script ftmp text aurl #:filename maybe-filename)
      (define filename (get-submod ftmp 'filename))

      ; Ask the user for a filename and directory.
      ; Notice: If the directory is not in the Library's paths, Quickscript may not find the script.
      ; TODO: Check that it's in the Library's path and display a warning if not?
      (define fout (put-file "url2script: Save script as…"
                            frame
                            dir
                            (or filename ".rkt")
                            ".rkt"
                            '()
                            '(("Racket source" "*.rkt")
                              ("Any" "*.*"))))

      (when fout
        (write-script fout text str)
        (smart-open-file frame fout))
      #f)))

(define-script update-script
  #:label "Update current script"
  #:help-string "Updates a script that was downloaded with url2script"
  #:menu-path ("url2script")
  (λ (selection #:file f #:frame drfr)
    (when f
      (define submod-url (get-submod f 'url))
        
      (cond
        [submod-url
         (define-values (aurl _name) (parse-url submod-url))
         (define text (get-text-at-url aurl))
         (define res
           (message-box "Attention"
                        "This will rewrite the current file. Continue?"
                        #f
                        '(ok-cancel caution)))
         (when (eq? res 'ok)
           (write-script f text aurl)
           (when drfr (send drfr revert)))]
        [else
         (message-box
          "Error"
          "Unable to find original url. Script may not have been downloaded with url2script."
          #f
          '(ok stop))]))
    #f))

(define-script visit-script-at-url
  #:label "Visit published script (browser)"
  #:menu-path ("url2script")
  (λ (selection #:file f)
    (when f
      (define submod-url (get-submod f 'url))
        
      (cond
        [submod-url
         (send-url submod-url)]
        [else
         (message-box
          "Error"
          "Unable to find original url. Script may not have been downloaded with url2script."
          #f
          '(ok stop))]))))

(define-script more-scripts
  #:label "Get more scripts (browser)"
  #:menu-path ("url2script")
  #:help-string "Opens the Racket wiki page for DrRacket Quickscript scripts."
  (λ (str) 
    (send-url "https://github.com/racket/racket/wiki/Quickscript-Scripts-for-DrRacket")
    #f))

;=============;
;=== Tests ===;
;=============;

(module+ test
  (require rackunit)

  (let ()
    (define f (make-temporary-file))
    (define aurl "https://this.is.your/home/now")
    (write-script f "#lang racket/base\n" aurl)
    (check-equal? (has-submod? f) #t)
    (check-equal? (get-submod f 'url)
                  aurl)

    (write-to-file '(module mymod racket/base (displayln "yop")) f #:exists 'replace)
    (check-equal? (has-submod? f) #f)
    ; syntax error
    (check-exn exn:fail? (λ () (write-script f "#lang racket/base\nraise-me-well!\n" aurl)))
    )

  (define (test-parse-url url)
    (call-with-values (λ () (parse-url url)) list))
  
  (check-equal?
   (test-parse-url "https://gist.github.com/Metaxal/f5ea8e94b802eac947fe9ea72870624b")
   '("https://gist.github.com/Metaxal/f5ea8e94b802eac947fe9ea72870624b/raw"
     #f))
  (check-equal?
   (test-parse-url "https://gist.github.com/Metaxal/f5ea8e94b802eac947fe9ea72870624b/raw")
   '("https://gist.github.com/Metaxal/f5ea8e94b802eac947fe9ea72870624b/raw"
     #f))

  (check-equal?
   (test-parse-url "https://gist.githubusercontent.com/Metaxal/4449e/raw/342e/letterfall.rkt")
   (list "https://gist.githubusercontent.com/Metaxal/4449e/raw/342e/letterfall.rkt"
         "letterfall.rkt"))

  (check-equal?
   (test-parse-url "https://gist.github.com/Metaxal/b2f6c446bded83962d3341bb79199734#file-upcase-rkt")
   ; Filename is a little annoying to parse
   (list "https://gist.github.com/Metaxal/b2f6c446bded83962d3341bb79199734/raw"
         #f))
  (check-equal?
   (test-parse-url "https://gist.github.com/Metaxal/b2f6c446bded83962d3341bb79199734?path=something")
   (list "https://gist.github.com/Metaxal/b2f6c446bded83962d3341bb79199734/raw"
         #f))

  (check-equal?
   (test-parse-url "https://pastebin.com/EMfcc5zs")
   (list "https://pastebin.com/raw/EMfcc5zs" #f))

  (check-equal?
   (test-parse-url "https://pastebin.com/raw/EMfcc5zs")
   (list "https://pastebin.com/raw/EMfcc5zs" #f))

  (check-equal?
   (test-parse-url "http://pasterack.org/pastes/8953")
   (list "http://pasterack.org/pastes/8953/raw" #f))

  (check-equal?
   (test-parse-url "http://pasterack.org/pastes/8953/raw")
   (list "http://pasterack.org/pastes/8953/raw" #f))

  (check-equal?
   (test-parse-url "https://gitlab.com/snippets/1997854")
   (list "https://gitlab.com/snippets/1997854/raw" #f))

  (check-equal?
   (test-parse-url "https://gitlab.com/snippets/1997854/raw")
   (list "https://gitlab.com/snippets/1997854/raw" #f))

  ;; TODO: Check that updating a script where the source does not have a url2script-info
  ;; submodule produces a script that still has the submodule

  
  )
