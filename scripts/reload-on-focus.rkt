#lang racket/gui
(require racket/class
         racket/file
         racket/port
         framework
         quickscript)

(script-help-string
 "Automatically reloads files in DrRacket when they are modified externally.
Shows a conflict dialog if there are also unsaved changes in DrRacket.")

;; Register preferences
(with-handlers ([exn:fail? void])
  (preferences:set-default 'quickscript:extra:reload-on-focus:enabled? #t boolean?))
(with-handlers ([exn:fail? void])
  (preferences:set-default 'quickscript:extra:reload-on-focus:diff-tool 'auto 
                           (λ (x) (or (eq? x 'auto) (string? x) (path? x)))))

;; Map to keep track of the last modification time we prompted the user for,
;; to avoid prompting repeatedly for the same external change if they choose "Keep".
(define prompted-mtimes (make-hash)) ; path -> mtime

;; Map to keep track of files currently being compared in diff tool,
;; to avoid prompting again while the tool is open or during transition.
(define diff-running-files (make-hash)) ; path -> #t

(define (file-contents=? p1 p2)
  (with-handlers ([exn:fail? (λ (e) #f)])
    (equal? (file->string p1) (file->string p2))))

(define (detect-gui-diff-tool)
  (case (system-type)
    [(windows)
     (or (find-executable-path "WinMergeU.exe")
         (find-executable-path "WinMerge.exe")
         (let ([pm (getenv "ProgramFiles")])
           (and pm
                (let ([p (build-path pm "WinMerge" "WinMergeU.exe")])
                  (and (file-exists? p) p))))
         (find-executable-path "DiffMerge.exe"))]
    [(macosx)
     (or (find-executable-path "opendiff")
         (find-executable-path "meld")
         (find-executable-path "DiffMerge"))]
    [(unix)
     (or (find-executable-path "meld")
         (find-executable-path "kdiff3")
         (find-executable-path "diffuse")
         (find-executable-path "DiffMerge"))]
    [else #f]))

(define (detect-cli-diff-tool)
  (or (find-executable-path "diff")
      (and (eq? (system-type) 'windows)
           (or (find-executable-path "fc.exe")
               (find-executable-path "fc")))))

(define (get-diff-command temp-file file)
  (define tool (preferences:get 'quickscript:extra:reload-on-focus:diff-tool))
  (define tool-path
    (if (eq? tool 'auto)
        (detect-gui-diff-tool)
        (if (string? tool) (find-executable-path tool) tool)))
  
  (if tool-path
      (values 'gui tool-path (list (path->string temp-file) (path->string file)))
      ;; If no GUI tool, try CLI tool
      (let ([cli-tool (detect-cli-diff-tool)])
        (if cli-tool
            (cond
              [(or (equal? (file-name-from-path cli-tool) (string->path "diff"))
                   (equal? (file-name-from-path cli-tool) (string->path "diff.exe")))
               (values 'cli cli-tool (list "-u" (path->string temp-file) (path->string file)))]
              [(or (equal? (file-name-from-path cli-tool) (string->path "fc"))
                   (equal? (file-name-from-path cli-tool) (string->path "fc.exe")))
               (values 'cli cli-tool (list "/N" (path->string temp-file) (path->string file)))]
              [else
               (values 'cli cli-tool (list (path->string temp-file) (path->string file)))])
            (values 'none #f #f)))))

(define (run-cli-diff tool-path args)
  (define-values (sp stdout stdin stderr)
    (apply subprocess #f 'pipe #f 'pipe tool-path args))
  (subprocess-wait sp)
  (define out-str (port->string stdout))
  (define err-str (port->string stderr))
  (close-input-port stdout)
  (close-input-port stderr)
  (if (string=? out-str "")
      err-str
      out-str))

(define (show-cli-diff-dialog diff-text defs file frame)
  (define d (new dialog% 
                 [label "Conflict Viewer (Read-Only Diff)"] 
                 [parent frame] 
                 [width 700] 
                 [height 500]))
  (define t (new text%))
  (send t insert diff-text)
  (send t set-read-only #t)
  (new editor-canvas% [parent d] [editor t])
  
  (define button-panel (new horizontal-panel% [parent d] [alignment '(center center)] [stretchable-height #f]))
  
  (define choice #f)
  (new button% 
       [label "Keep DrRacket changes"] 
       [parent button-panel] 
       [callback (λ (b e) 
                   (set! choice 'keep)
                   (send d show #f))])
  (new button% 
       [label "Revert (Discard DrRacket changes)"] 
       [parent button-panel] 
       [callback (λ (b e) 
                   (set! choice 'revert)
                   (send d show #f))])
  
  (send d show #t)
  choice)

(define (check-and-reload defs file frame)
  (when (and (preferences:get 'quickscript:extra:reload-on-focus:enabled?)
             defs file (file-exists? file)
             (not (hash-ref diff-running-files file #f)))
    (define disk-mtime (file-or-directory-modify-seconds file))
    (define last-prompted (hash-ref prompted-mtimes file 0))
    ;; Only act if the file on disk is newer than when we last loaded/saved/prompted
    (when (and (send defs save-file-out-of-date?)
               (> disk-mtime last-prompted))
      (if (send defs is-modified?)
          (begin
            ;; Mark as prompted immediately to avoid duplicate prompts while dialog is open
            (hash-set! prompted-mtimes file disk-mtime)
            (handle-conflict defs file frame))
          (begin
            (send defs revert/gui-error)
            ;; Update mtime after successful revert
            (hash-set! prompted-mtimes file (file-or-directory-modify-seconds file)))))))

(define-hook on-focus
  #:persistent
  (λ (#:definitions defs #:file file #:frame frame)
    (check-and-reload defs file frame)))

(define (handle-conflict defs file frame)
  (define filename (path->string file))
  (define choice
    (message-box/custom
     "File Changed Externally"
     (format "File ~a has been modified externally, but also has unsaved changes in DrRacket.\n\nWhat do you want to do?" filename)
     "Keep DrRacket changes"
     "Revert (Discard DrRacket changes)"
     "Compare..."
     frame
     '(caution default=3)
     1))
  (case choice
    [(1) (void)] ; Keep changes, do nothing (won't prompt again until next external save)
    [(2) (send defs revert/gui-error)]
    [(3) (run-diff defs file frame)]))

(define (run-diff defs file frame)
  (let* ([temp-file (make-temporary-file "drracket-tmp-~a.rkt")]
         [filename (path->string file)])
    (call-with-output-file temp-file
      #:exists 'truncate/replace
      (λ (out)
        (send defs save-port out 'text)))
    
    (define-values (type tool-path args) (get-diff-command temp-file file))
    (case type
      [(gui)
       (hash-set! diff-running-files file #t)
       (thread
        (λ ()
          (define-values (sp stdout stdin stderr)
            (apply subprocess #f #f #f tool-path args))
          (subprocess-wait sp)
          
          (define same? (and (file-exists? temp-file)
                             (file-exists? file)
                             (file-contents=? temp-file file)))
          (delete-file temp-file)
          
          (queue-callback
           (λ ()
             (define current-disk-mtime (and (file-exists? file) (file-or-directory-modify-seconds file)))
             (when (send defs save-file-out-of-date?)
               (if same?
                   (send defs revert/gui-error)
                   (when (eq? 'yes (message-box "Diff Finished"
                                             "Diff tool has closed. Do you want to reload the file now? Unsaved changes in DrRacket will be overwritten."
                                             frame
                                             '(yes-no caution)))
                     (send defs revert/gui-error))))
             (when current-disk-mtime
               (hash-set! prompted-mtimes file current-disk-mtime))
             (hash-remove! diff-running-files file)))))]
      [(cli)
       (hash-set! diff-running-files file #t)
       (thread
        (λ ()
          (define diff-text (run-cli-diff tool-path args))
          (delete-file temp-file)
          (queue-callback
           (λ ()
             (define current-disk-mtime (and (file-exists? file) (file-or-directory-modify-seconds file)))
             (when (send defs save-file-out-of-date?)
               (define choice (show-cli-diff-dialog diff-text defs file frame))
               (when (eq? choice 'revert)
                 (send defs revert/gui-error)))
             (when current-disk-mtime
               (hash-set! prompted-mtimes file current-disk-mtime))
             (hash-remove! diff-running-files file)))))]
      [else
       (delete-file temp-file)
       (message-box "Error" "No diff tool (GUI or CLI) was found." frame '(ok error))])))

;; Menu item to toggle the feature
(define-script toggle-reload-on-focus
  #:label "Toggle auto-reload on focus"
  #:menu-path ("Manage")
  (λ (str)
    (define new-val (not (preferences:get 'quickscript:extra:reload-on-focus:enabled?)))
    (preferences:set 'quickscript:extra:reload-on-focus:enabled? new-val)
    (message-box "Auto-reload on focus"
                 (format "Auto-reload on focus is now ~a." (if new-val "ENABLED" "DISABLED"))
                 #f
                 '(ok info))
    str))
