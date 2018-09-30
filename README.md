# Quickscript Extra

Some scripts for [Quickscript](https://github.com/Metaxal/quickscript),
which must be installed first.

## 1. Installation

* From DrRacket:

In DrRacket, in `File>Package` `manager>Source`, type
`https://github.com/Metaxal/quickscript-extra.git`.
Then evaluate:
```scheme
(require quickscript-extra/register)
```

If DrRacket is already running, click on
`Scripts>Manage` `scripts>Compile` `scripts` `and` `reload` `menu`.

* Or from the coommand line:

```racket
raco pkg install https://github.com/Metaxal/quickscript-extra.git
```
Then register the new list of scripts in quickscript either by
evaluating in DrRacket:
```shell
$ racket -l quickscript-extra/register
```

## 2. Scripts

* **abstract-variable**: Create a variable from the selected expression
  \(video: https://www.youtube.com/watch?v=qgjAZd4eBBY\).

* **add-menu**: \(Example\) Shows how to dynamically add a menu to
  DrRacket.

* **author-date**: Insert text snippets with author, date, time, and
  licence.

* **bookmarks**: Quickly navigate between lines

* **color-chooser**: Pick a color in the palette and insert it in
  DrRacket’s current file.

* **color-theme**: Display information about the current color theme.

* **complete-word**: Word completion from a give user dictionary

* **current-file-example**: \(Example\) Displays the current file and
  the current selected string in a message box.

* **def-signatures**: Displays the signature of the procedure under the
  cursor \(like DrRacket’s blue box but works also when the file does
  not compile\).

* **dynamic-abbrev**: Cyclice word completion using the words of the
  current file.

* **enter-submod**: Easily enter a submodule \(main, test, drracket,
  etc.\) in the interaction window.

* **filepath-to-clipboard**: Write the path of the current file in the
  clipboard.

* **git**: Some git commands \(linux only\). Currently meant as a demo.

* **goto-line**: Jump to a given line number in the current editor.

* **gui-tools**: Code snippets for racket/gui widgets. Meant as a demo.

* **indent-table**: Indent rows on double-space-separated colums
  \(video: https://www.youtube.com/watch?v=KJjVREsgnvA\).

* **insert-pict**: \(Example\) Insert a ‘pict‘ at the current position.

* **number-tabs**: \(Example\) displays the number of opened tabs in a
  message box.

* **open-collect-file**: Open a file in DrRacket, starting in racket’s
  collections base path.

* **open-dir**: Open the system’s file browser in the current directory.

* **open-terminal**: Open a terminal in the current directory \(linux
  only\).

* **pasterack**: Opens Pasterack in the browser.

* **persistent-counter**: \(Example\) Shows how the ‘\#:persistent‘
  property works.

* **provided-by**: Displays a list of modules that ‘provide‘ the
  procedure under the cursor.

* **regexp-replace**: Replace patterns in the selected text using
  regular expressions.

* **reorder-tabs**: \(Example\) Move DrRacket’s tabs around.

* **reverse-selection**: \(Example\) The simplest script example:
  reverse the selected string.

* **sections**: Surrounds the selected text by comments ASCII frames.

* **sort-lines**: Sorts the selected lines in \(anti-\)alphabetical
  order.

* **surround-selection**: \(Example\) Surround the selected text with
  various characters.

* **tweet**: \(Example\) Tweet the current selection. See the script
  file for configuration details.

## 3. Uninstall

Before removing the package, first evaluate `(require
quickscript-extra/unregister)`, or on the command line with
`$` `racket` `-l` `quickscript-extra/unregister`.

Then remove the package, either from DrRacket’s `File` menu, or on the
command line with `$` `raco` `pkg` `remove` `quickscript-extra`.
