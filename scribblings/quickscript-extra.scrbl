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

@section{url2script}

The @tt{url2script} script is special: it allows you to easily fetch single-file quickscripts from
anywhere on the internet by providing the url to the raw code.
It is actually a little smarter than that because it understands non-raw urls from
@hyperlink["https://gist.github.com"]{github gists},
@hyperlink["https://gitlab.com/snippets"]{gitlab snippets},
@hyperlink["https://pastebin.com"]{pastebin} and
@hyperlink["http://pasterack.org"]{pasterack}.

Some single-file scripts can be found on the
@hyperlink["https://github.com/racket/racket/wiki/Quickscript-Scripts-for-DrRacket"]{Racket wiki}.

A script previously fetched with url2script can also be easily updated by first opening it via
@tt{Scrits|Manage|Open script…} then clicking on @tt{Scripts|url2script|Update current script}.

When a script is fetched by @tt{url2script}, a @racketid{url2script-info} submodule is
automatically added (unless one already exists) with information about the filename in which the
script is to be saved (or has been saved), and the original url of the script.
The latter is used for updating the script as described above.
The submodule looks like this:
@racketblock[
 (module url2script-info racket/base
  (provide url filename)
  (define filename "the-default-filename-to-save-the-script.rkt")
  (define url "https://url.of.the/script.rkt"))
]
If you want to publish a single-file quickscript without making a package, consider adding this
submodule so as to provide a default filename (otherwise the user who fetches your script will have to
type one themselves, and may be unsure what name to pick).

Also consider adding a permissive license. We recommend a dual license Apache 2.0 / MIT:
@racketblock[
 #,(elem ";;; Copyright <year> <email or name or entity> ")
 #,(elem ";;; License: [Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0) or")
 #,(elem ";;;          [MIT license](http://opensource.org/licenses/MIT) at your option.")
]

Scripts fetched by @tt{url2script} are added to the default script directory.
They can be modified as desired (as long as the license permits it)

@section{Customizing}

Scripts can be selectively deactivated from the library
(@tt{Scripts|Manage scripts|Library}).

If you change the source code of a script installed from the @tt{quickscript-extra} package
(or from any package containing quickscripts), you will lose all your modifications when the package
is updated.
To avoid this, you can use Quickscript's
@hyperlink["https://docs.racket-lang.org/quickscript/index.html?q=quickscripts#%28part._.Shadow_scripts%29"]{shadow scripts}:
The shadow script calls the original script without modifying it, and can be modified to your taste
without being modified when the original script is updated.

In particular, if you want to change the default label, menu path or keybinding of a script installed
from @tt{quickscript-extra}, go to @tt{Scripts|Manage|Library…}, select the @tt{quickscript-extra}
directory, then the script you want, and click on @tt{Shadow}.
This opens a new (shadow) script that calls the original script where you can change what you want.

Note that the shadowed script is deactivated so as to avoid duplicate menu entries and keybindings.
