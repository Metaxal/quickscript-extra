# Quickscript Extra

Some scripts for [Quickscript](https://github.com/Metaxal/quickscript).

## 1. Installation

In DrRacket, in `File|Package manager|Source`, enter
`quickscript-extra`.

Or, on the command line, type: `raco pkg install quickscript-extra`.

If DrRacket is already running, click on `Scripts|Manage scripts|Compile
scripts and reload menu`.

## 2. Scripts

* **abstract-variable**: Create a variable from the selected expression
  [video](https://www.youtube.com/watch?v=qgjAZd4eBBY)

* **add-menu**: \(Example\) Shows how to dynamically add a menu to
  DrRacket.

* **all-tabs**: Have a menu that displays all open tabs in DrRacket.

* **author-date**: Insert text snippets with author, date, time, and
  licence.

* **backup-file**: Copies the current file in the ’backups’ subdirectory
  with a time stamp

* **bookmarks**: Quickly navigate between lines

* **color-chooser**: Pick a color in the palette and insert it in
  DrRacket’s current file.

* **color-theme**: Display information about the current color theme.

* **complete-word**: Word completion from a give user dictionary

* **current-file-example**: \(Example\) Displays the current file and
  the current selected string in a message box.

* **def-signatures**: Displays the signature of the procedure under the
  cursor (like DrRacket’s blue box but works also when the file does not
  compile).

* **dynamic-abbrev**: Cyclic word completion using the words of the
  current file.

* **enter-submod**: Easily enter a submodule (main, test, drracket,
  etc.) in the interaction window.

* **extract-function**: Extracts a block of code out of its context and
  generates a function and a call
  [video](https://www.youtube.com/watch?v=XinMxDLZ7Zw)

* **filepath-to-clipboard**: Write the path of the current file in the
  clipboard.

* **git**: Some git commands (linux only). Currently meant as a demo.

* **goto-line**: Jump to a given line number in the current editor.

* **gui-tools**: Code snippets for racket/gui widgets. Meant as a demo.

* **indent-table**: Indent rows on double-space-separated columns
  [video](https://www.youtube.com/watch?v=KJjVREsgnvA)

* **insert-pict**: \(Example\) Insert a ‘pict‘ at the current position.

* **number-tabs**: \(Example\) displays the number of opened tabs in a
  message box.

* **open-collect-file**: Open a file in DrRacket, starting in racket’s
  collections base path.

* **open-dir**: Open the system’s file browser in the current directory.

* **open-terminal**: Open a terminal in the current directory.

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

* **sort-lines**: Sorts the selected lines in (anti-)alphabetical order.

* **surround-selection**: \(Example\) Surround the selected text with
  various characters.

* **tweet**: \(Example\) Tweet the current selection. See the script
  file for configuration details.

## 3. Customizing

If the default keybindings, names or submenus are not to you taste, they
can be fully customized using Quickscript’s [shadow
scripts](https://docs.racket-lang.org/quickscript/index.html?q=quickscripts#%28part._.Shadow_scripts%29).

Scripts can also be deactivated altogether from the library
\(`Scripts|Manage scripts|Library`).
