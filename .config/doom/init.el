;;; init.el -*- lexical-binding: t; -*-
;; Copy me to ~/.doom.d/init.el or ~/.config/doom/init.el, then edit me!


(doom! :feature
       :completion
       (company          ; the ultimate code completion backend
        +auto            ; as-you-type code completion
        +childframe)     ; a nicer company UI. Emacs +26 only!
       (ivy
        +icons
        +prescient
        +fuzzy)          ; a search engine for love and life

       :ui
       deft
       workspaces        ; tab emulation, persistence & separate workspaces
       doom              ; what makes DOOM look the way it does
       doom-dashboard    ; a nifty splash screen for Emacs
       modeline          ; a snazzy Atom-inspired mode-line
       ophints                      ; highlight the region an operation acts on
       doom-quit         ; DOOM quit-message prompts when you quit Emacs
       ophints           ; display visual hints when editing in evil
       hl-todo           ; highlight TODO/FIXME/NOTE tags
       nav-flash         ; blink the current line after jumping
       treemacs          ; a project drawer, like neotree but cooler
       vc-gutter                    ; vcs diff in the fringe
       vi-tilde-fringe              ; fringe tildes to mark beyond eob
       (popup            ; tame sudden yet inevitable temporary windows
        +all             ; catch all popups that start with an asterix
        +defaults)       ; default popup rules
       ;;(ligatures +extra)           ; ligatures and symbols to make your code pretty again
       (window-select +numbers)     ; visually switch windows
       zen                          ; distraction-free coding or writing

       :emacs
       (dired +icons); making dired pretty [functional]
       electric          ; smarter, keyword-based electric-indent
       (ibuffer +icons)             ; interactive buffer management
       (undo +tree)                 ; persistent, smarter undo for your inevitable mistakes
       vc                ; version-control and Emacs, sitting in a tree

       :term
       vterm ; the best terminal emulation in Emacs


       :editor
       (evil +everywhere); come to the dark side, we have cookies
       file-templates    ; auto-snippets for empty files
       fold
       multiple-cursors  ; editing in many places at once
       snippets          ; my elves. They type so I don't have to
       ;;parinfer          ; turn lisp into python, sort of
       rotate-text       ; cycle region at point between text candidates
       (format)                     ; automated prettiness
       rotate-text                  ; cycle region at point between text candidates

       :tools
       taskrunner        ; taskrunner for gradle, make etc
       eval              ; run code, run (also, repls)
       gist              ; interacting with github gists
       make              ; run make tasks from Emacs
       (magit +forge)             ; a git porcelain for Emacs
       pass          ; password manager for nerds
       pdf               ; pdf enhancements
       rgb               ; creating color strings
       debugger                   ; FIXME stepping through code, to help you add bugs
       lsp                          ; Language Server Protocol
       direnv                     ; be direct about your environment
       docker                       ; port everything to containers
       editorconfig               ; let someone else argue about tabs vs spaces
       ein                        ; tame Jupyter notebooks with emacs
       ;;tmux              ; an API for interacting with tmux
       upload            ; map local to remote projects via ssh/ftp
       flycheck
       flyspell

       :lang
        assembly          ; assembly for fun or debugging
        (cc +lsp)                ; C/C++/Obj-C madness
       ;; crystal           ; ruby at the speed of c
       ;; clojure           ; java with a lisp
       ;; csharp            ; unity, .NET, and mono shenanigans
       common-lisp
       data              ; config/data formats
                                        ;erlang            ; an elegant language for a more civilized age
       ;; elixir            ; erlang done right
       ;; elm               ; care for a cup of TEA?
       emacs-lisp        ; drown in parentheses
       ess               ; emacs speaks statistics
       go                ; the hipster dialect
       ;; (haskell +intero) ; a language that's lazier than I am
       ;; hy                ; readability of scheme w/ speed of python
       (java +lsp) ; the poster child for carpal tunnel syndrome
       (javascript +lsp)            ; all(hope(abandon(ye(who(enter(here))))))
       (julia +lsp)                 ; a better, faster MATLAB
       ;; julia             ; a better, faster MATLAB
       (latex                       ; writing papers in Emacs has never been so fun
       +latexmk                    ; what else would you use?
       +cdlatex                    ; quick maths symbols
       +fold)                      ; fold the clutter away nicities
       ;; ledger            ; an accounting system in Emacs
       ;; lua               ; one-based indices? one-based indices
       markdown          ; writing docs for people to ignore
       ;; nix               ; I hereby declare "nix geht mehr!"
       ;; ocaml             ; an objective camel
       (org              ; organize your plain life in plain text
        +attach          ; custom attachment system
        +journal
        +babel           ; running code in org
        +hugo            ; Write hugo posts in org-mode
        +gnuplot         ; Who doesn't love plots
        +roam            ; roam around your notes
        +pandoc                     ; export-with-pandoc support
        +pretty                     ; yessss my pretties! (nice unicode symbols)
        +capture         ; org-capture in and outside of Emacs
        +export          ; Exporting org to whatever you want
        +present)         ; Emacs for presentations
        +publish        ; Emacs+Org as a static site generator

       ;; perl              ; write code no one else can comprehend
       php               ; perl's insecure younger brother
       ;; plantuml          ; diagrams for confusing people more
       ;; purescript        ; javascript, but functional
       (python +lsp +pyright)            ; beautiful is better than ugly
       rest              ; Emacs as a REST client
       ;; ruby              ; 1.step do {|i| p "Ruby is #{i.even? ? 'love' : 'life'}"}
       ;; rust              ; Fe2O3.unwrap().unwrap().unwrap().unwrap()
       ;; scala             ; java, but good
       (sh +lsp)                ; she sells (ba|z)sh shells on the C xor
       ;; swift             ; who asked for emoji variables?
       web               ; the tubes

       ;; Applications are complex and opinionated modules that transform Emacs
       ;; toward a specific purpose. They may have additional dependencies and
       ;; should be loaded late.
       :app
       ;;(:if (executable-find "mu") (mu4e +org +gmail))
       ;;notmuch
       ;;(wanderlust +gmail)
       calendar                   ; A dated approach to timetabling
       ;;emms                       ; Multimedia in Emacs is music to my ears
       everywhere                   ; *leave* Emacs!? You must be joking.
       ;;irc                          ; how neckbeards socialize
       (rss +org)                   ; emacs as an RSS reader
       twitter                    ; twitter client https://twitter.com/vnought
       :config
       ;; The default module set reasonable defaults for Emacs. It also provides
       ;; a Spacemacs-inspired keybinding scheme, a custom yasnippet library,
       ;; and additional ex commands for evil-mode. Use it as a reference for
       ;; your own modules.
       (default +bindings +snippets +evil-commands +smartparens))

(add-load-path! "lisp/")
