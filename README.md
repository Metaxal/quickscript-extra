Some scripts for [Quickscript](https://github.com/Metaxal/quickscript).

# Installation

```
raco pkg install https://github.com/Metaxal/quickscript-extra.git
```
Then register the new list of scripts in quickscript either by evaluating 
`(require quickscript-extra/register)` in DrRacket, or on the command line with
`$ racket -l quickscript-extra/register`.

If DrRacket is already running, click on `Scripts>Manage scripts>Compile scripts and reload menu`.

# Scripts

(TODO: to update)

This package contains the following scritps:
* **abstract**: When you want to replace an expression with a variable
    https://www.youtube.com/watch?v=qgjAZd4eBBY
* **author-date**: Insert some combination of author-date-license strings in your files
* **bookmarks**: Add bookmarks in your files to quickly navigate between lines
* **color-chooser**: Pick a color graphically and insert it in DrRacket's current file
* **complete-word**: Word completion from a give user dictionary
* **def-signature**: Display the signature of a procedure or a form on top of DrRacket (predates DrRacket blue-box feature, but may still be useful when the file does not compile)
* **dynamic-abbrev**: Word completion for the words in the current file
* **git**: Unix-specific (uses xterm); Modify to suit your needs
* **goto-line**: A simple example to tweak DrRacket (but DrRacket already has this feature)
* **gui-tools**: A simple example on how to add gui definitions
* **indent-table**: Indent your line like a table. Useful for `let`s and `define`s
    https://www.youtube.com/watch?v=KJjVREsgnvA
* **open-dir**: Open the OS explorer in the directory of the file
* **open-terminal**: Opens a terminal in the directory of the current file; Unix specific 
* **regexp-replace**: Replace strings with regular expressions in DrRacket; Some default templates included
* **sections**: Add nice ascii boxes ind your source files
* **string-utils**: various string insertions in your files
* **test-menu**: Example to show how to add and remove a menu to DrRacket
* **test-slideshow**: Example to show how to insert slideshow images in DrRacket

# Uninstall

Before removing the package, first evaluate `(require quickscript-extra/unregister)`, 
or on the command line with `$ racket -l quickscript-extra/unregister`.

Then remove the package, either from DrRacket's `File` menu, or on the command line with
`$ raco pkg remove quickscript-extra`.
