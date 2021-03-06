#lang scribble/manual
@(require racket/runtime-path
          racket/dict
          racket/path
          racket/match
          quickscript/base)

@(define-runtime-path scripts-path "../scripts")

@;; If calling this function is slow, compile the scripts first.
@(define (get-script-help-strings scripts-path)
  (filter
   values
   (for/list ([filename (in-list (directory-list scripts-path #:build? #f))])
     (define filepath (build-path scripts-path filename))
     (and (script-file? filepath)
          (cons (path->string (path-replace-extension filename #""))
                (get-script-help-string filepath))))))
@(define help-strings (get-script-help-strings scripts-path))


@title{Quickscript Extra}

Some scripts for @(hyperlink "https://github.com/Metaxal/quickscript" "Quickscript").

@section{Installation}

In DrRacket, in @tt{File|Package manager|Source}, enter @tt{quickscript-extra}.

Or, on the command line, type: @tt{raco pkg install quickscript-extra}.

If DrRacket is already running, click on @tt{Scripts|Manage scripts|Compile scripts and reload menu}.

@section{Scripts}


@(itemlist
  (for/list ([(name str) (in-dict help-strings)])
     (item (index name @(bold name)) ": "
           (let loop ([str str])
             (match str
               ;; link
               [(regexp #px"^(.*)\\[([^]]+)\\]\\(([^)]+)\\)(.*)$" (list _ pre txt link post))
                (list (loop pre)
                      (hyperlink link txt)
                      (loop post))]
               [else str])))))

@section{Customizing}

If the default keybindings, names or submenus are not to your taste, they can be fully customized
using Quickscript's
@hyperlink["https://docs.racket-lang.org/quickscript/index.html?q=quickscripts#%28part._.Shadow_scripts%29"]{shadow scripts}.

Scripts can also be selectively deactivated from the library
(@tt{Scripts|Manage scripts|Library}).
