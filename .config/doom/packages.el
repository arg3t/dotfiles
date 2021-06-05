;;;  -*- lexical-binding: t; -*-
;;;  -*- no-byte-compile: t; -*-

(package! reason-mode)
(package! prettier-js)
(package! org-fancy-priorities)
(package! move-text)
(package! vue-mode)
(package! deadgrep)
(package! sql-indent)
(package! org-brain)
(package! calibredb)
(package! nov)
(package! xkcd)
(package! elcord)
(package! tiny)
(package! evil-escape :disable t)
(package! lexic :recipe (:local-repo "lisp/lexic"))

;; Latex Is Clearly Superior Right???
(package! aas :recipe (:host github :repo "ymarco/auto-activating-snippets"))
(package! laas :recipe (:local-repo "lisp/LaTeX-auto-activating-snippets"))
(package! auctex)
(package! calctex :recipe (:host github :repo "johnbcoughlin/calctex"
                           :files ("*.el" "calctex/*.el" "calctex-contrib/*.el" "org-calctex/*.el" "vendor")))

;; Org-Mode related
(package! org-super-agenda)
(package! org-caldav)
(package! doct
  :recipe (:host github :repo "progfolio/doct"))
(package! org-pretty-table
  :recipe (:host github :repo "Fuco1/org-pretty-table"))
(package! org-fragtog)
(package! org-appear :recipe (:host github :repo "awth13/org-appear"))
(package! org-pretty-tags)
(package! org-ol-tree :recipe (:host github :repo "Townk/org-ol-tree"))
(package! org-chef) ;; Real chefs use emacs

(package! javadoc-help)
(package! nand-hdl-mode
  :recipe (:host github :repo "nverno/nand-hdl-mode"))

(package! browse-kill-ring)
(package! olivetti)
(package! ox-hugo)
(package! polymode)
(package! counsel-org-clock)
(package! mathpix.el :recipe (:host github :repo "jethrokuan/mathpix.el"))
