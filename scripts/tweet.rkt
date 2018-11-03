#lang racket/base
(require racket/list
         racket/string
         quickscript)

(script-help-string "(Example) Tweet the current selection. See the script file for configuration details.")

;;; HOW TO USE
;;; to use this you need to
;;;
;;; 1. go to https://apps.twitter.com
;;; 2. create a new app (profile for your app)
;;; 3. create a new token
;;; 4. set the environment variables:
(define env-keys '("OAUTH_CONS_KEY" "CONS_SEC" "OAUTH_TOKEN" "OAUTH_TOKEN_SEC"))

(define-script tweet-selection
  #:label "Tweet"
  #:menu-path ("Sele&ction")
  #:output-to message-box
  (λ (str #:frame fr) 
    (define keys (map getenv env-keys))
    (if (member #f keys)
        (string-append "Please set the following environment variables\n"
                        (string-join env-keys ", ")
                        ".")
        (begin
          (tweet! str)
          #f))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Code below by David Van Horn  http://ter.ps/dvanhorn                   ;
; used with permission                                                   ;
; https://gist.github.com/dvanhorn/815bdda5cfcdee18d480cb6a5d1119f3      ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(require (only-in racket/random crypto-random-bytes)
         json
         net/url
         (only-in net/uri-codec [uri-unreserved-encode %])
         web-server/stuffers/hmac-sha1
         (only-in net/base64 base64-encode))

;; For description, see:
;; https://developer.twitter.com/en/docs/basics/authentication/guides/authorizing-a-request


;; tweet! : String -> JSON
;; Post a tweet!, return JSON response
(define (tweet! status oauth-consumer-key consumer-sec oauth-token oauth-token-sec)
  (define url "https://api.twitter.com/1.1/statuses/update.json")
  (define oauth-nonce (nonce))
  (define timestamp (number->string (current-seconds)))
  (define ++ string-append)
  (define (& s) (apply ++ (add-between s "&")))

  (define (encode msg)
    (& (map (λ (e) (string-append (first e) "=" (second e)))
            (sort (map (λ (e) (list (% (first e)) (% (second e)))) msg)
                  (λ (elem1 elem2) (string<=? (car elem1) (car elem2)))))))
  
  (define parameter-string
    (encode `(("status" ,status)
              ("include_entities" "true")
              ("oauth_consumer_key" ,oauth-consumer-key)    
              ("oauth_nonce" ,oauth-nonce)
              ("oauth_signature_method" "HMAC-SHA1")
              ("oauth_timestamp" ,timestamp)
              ("oauth_token" ,oauth-token)
              ("oauth_version" "1.0"))))
  
  (define sig-base-string
    (++ "POST&" (% url) "&" (% parameter-string)))
  
  (define signing-key
    (++ (% consumer-sec) "&" (% oauth-token-sec)))
  
  (define oauth-signature
    (bytes->string/utf-8 
     (base64-encode (HMAC-SHA1 (string->bytes/utf-8 signing-key)
                               (string->bytes/utf-8 sig-base-string))
                    #"")))
  
  (define header
    (list "Accept: */*"
          "Connection: close"
          "Content-Type: application/x-www-form-urlencoded"
          (++ "Authorization: OAuth "
              "oauth_consumer_key=\"" (% oauth-consumer-key) "\", "
              "oauth_nonce=\"" oauth-nonce "\", "
              "oauth_signature=\"" (% oauth-signature) "\", "
              "oauth_signature_method=\"HMAC-SHA1\", "
              "oauth_timestamp=\"" timestamp "\", "
              "oauth_token=\"" (% oauth-token) "\", "
              "oauth_version=\"1.0\"")))
  
  (read-json
   (post-pure-port
    (string->url (++ url "?include_entities=true"))
    (string->bytes/utf-8 (++ "status=" (% status)))
    header)))



;; nonce : -> String
;; Creates 32 bytes of random alphabetic data
(define (nonce) 
  (define (int->alpha i)
    (define a (modulo i 52))
    (integer->char
     (cond [(<= 0 a 25) (+ a 65)]
           [(<= 26 a 52) (+ a 97 -26)])))
  (apply string
         (map int->alpha
              (bytes->list (crypto-random-bytes 32)))))
