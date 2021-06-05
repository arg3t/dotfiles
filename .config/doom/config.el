;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; __   _______ _____ _____
;; \ \ / / ____| ____|_   _|
;;  \ V /|  _| |  _|   | |
;;   | | | |___| |___  | |
;;   |_| |_____|_____| |_|
;; Yeet's Doom Emacs configuration


;; Global Configuration
(setq user-full-name "Yigit Colakoglu"
user-mail-address "yigit@yigitcolakoglu.com")

(setq org-directory "~/Documents/org/")
(setq org-journal-dir "~/Documents/org/journal/")
(setq display-line-numbers-type 'relative)
(setq twittering-allow-insecure-server-cert t)

(setq +ivy-buffer-preview t)
(global-auto-revert-mode t)
(global-subword-mode 1)                           ; Iterate through CamelCase words

(setq-default
        delete-by-moving-to-trash t                      ; Delete files to trash
        window-combination-resize t                      ; take new window space from all other windows (not just current)
        x-stretch-cursor t)                              ; Stretch cursor to the glyph width

(setq undo-limit 80000000                         ; Raise undo-limit to 80Mb
        evil-want-fine-undo t                       ; By default while in insert all changes are one big blob. Be more granular
        auto-save-default t                         ; Nobody likes to loose work, I certainly don't
        truncate-string-ellipsis "…")               ; Unicode ellispis are nicer than "...", and also save /precious/ space


;; Experimental, delete if you don't like it
(setq evil-vsplit-window-right t
      evil-split-window-below t)

(require 'bison-mode)
(after! bison-mode-hook
  (setq imenu-create-index-function
        (lambda ()
                (let ((end))
                (beginning-of-buffer)
                (re-search-forward "^%%")
                (forward-line 1)
                (setq end (save-excursion (re-search-forward "^%%") (point)))
                (loop while (re-search-forward "^\\([a-z].*?\\)\\s-*\n?\\s-*:" end t)
                        collect (cons (match-string 1) (point)))))))

(defadvice! prompt-for-buffer (&rest _)
  :after '(evil-window-split evil-window-vsplit)
  (+ivy/switch-buffer))

(use-package! ox-hugo
  :after ox
  )

(use-package! elfeed-org
  :after elfeed
  :config
  (elfeed-org)
  (setq rmh-elfeed-org-files (list "~/.doom.d/elfeed.org"))
  )

(use-package! deft
  :hook deft-mode-hook
  :init
  (setq deft-directory org-directory)
  (setq deft-recursive t)
  )

(use-package! hl-todo
  :hook (prog-mode . hl-todo-mode)
  :config
  (setq hl-todo-keyword-faces
        `(
          ("PROJ"  . ,(face-foreground 'error))
          ("SOMEDAY"  . ,(face-foreground 'warning))
          ("TODO"  . ,(face-foreground 'warning))
          ("PROG" . ,(face-foreground 'error))
          ("NEXT" . ,(face-foreground 'error))
          ("WAIT" . ,(face-foreground 'warning))
          ("CANCEL" . ,(face-foreground 'error))
          ("DELEGATED" . ,(face-foreground 'error))
          ("IDEA" . ,(face-foreground 'warning))
          ("GOAL" . ,(face-foreground 'warning))
          ("DUD" . ,(face-foreground 'error))
          ("RD" . ,(face-foreground 'warning))
          ("RDING" . ,(face-foreground 'warning))
          ("RDNOTE" . ,(face-foreground 'warning))
          ("TMPDROP" . ,(face-foreground 'warning))
          ("DROP" . ,(face-foreground 'error))
          ("FNSHED" . ,(face-foreground 'success))
          ("DONE"  . ,(face-foreground 'success)))))

(use-package! engrave-faces-latex
  :after ox-latex)

(use-package! org-ol-tree
  :commands org-ol-tree)

(use-package! org-chef
  :commands (org-chef-insert-recipe org-chef-get-recipe-from-url))

(use-package! org-pretty-table
  :commands (org-pretty-table-mode global-org-pretty-table-mode))

(use-package! aas :commands aas-mode)

(use-package! laas
  :hook (LaTeX-mode . laas-mode)
  :config
  (defun laas-tex-fold-maybe ()
    (unless (equal "/" aas-transient-snippet-key)
      (+latex-fold-last-macro-a)))
  (add-hook 'aas-post-snippet-expand-hook #'laas-tex-fold-maybe))

(use-package! calfw-org
  :after calfw)

(use-package! org-agenda
  :defer
  :init
  (setq org-agenda-files (list
                          (concat org-directory "projects.org")
                          (concat org-directory "monthly_habits.org")
                          (concat org-directory "quarterly_habits.org")
                          (concat org-directory "personal.org")
                          (concat org-directory "taxes.org")
                          (concat org-directory "birthdays_and_important_days.org")
                          (concat org-directory "reading_list.org")
                          (concat org-directory "school.org")
                          (concat org-directory "daily_habits.org")
                          (concat org-directory "weekly_habits.org")
                          (concat org-directory "reflections/2021_refl.org")
                          (concat org-directory "someday.org")
                          (concat org-directory "projects/2021/")
                          org-journal-dir))

  :config
  (setq org-habit-show-habits-only-for-today t)
  ;; Org Agenda Files

  ;; org agenda
  (setq org-agenda-time-grid
        (quote
         ((daily today remove-match)
          (700 800 900 1000 1100 1200 1300 1400 1500 1600 1700 1800 1900 2000 2100 2200 2300)
          "......" "----------------")))
  )

(use-package! org-super-agenda
  :after org-agenda
  :init
  ;; for some reason org-agenda evil bindings were being weird with j and k
  (map! :map org-agenda-keymap "j" #'org-agenda-next-line)
  (map! :map org-agenda-mode-map "j" #'org-agenda-next-line)
  (map! :map org-super-agenda-header-map "j" #'org-agenda-next-line)
  (map! :map org-agenda-keymap "k" #'org-agenda-previous-line)
  (map! :map org-agenda-mode-map "k" #'org-agenda-previous-line)
  (map! :map org-super-agenda-header-map "k" #'org-agenda-previous-line)
  (map! :map org-super-agenda-header-map "k" #'org-agenda-previous-line)
  (map! :map org-super-agenda-header-map "k" #'org-agenda-previous-line)

  (setq org-agenda-custom-commands '(
                                     ("r" "Main View"
                                      ((agenda "" ((org-agenda-span 'day)
                                                   (org-agenda-start-day "+0d")
                                                   (org-agenda-overriding-header "")
                                                   (org-super-agenda-groups
                                                    '((:name "Today"
                                                       :time-grid t
                                                       :date today
                                                       :order 1
                                                       :scheduled today
                                                       :todo "TODAY")))))
                                       (alltodo "" ((org-agenda-overriding-header "")
                                                    (org-super-agenda-groups
                                                     '(
                                                       (:discard (:habit))
                                                       (:todo "PROJ")
                                                       (:todo "PROG")
                                                       (:todo "NEXT")
                                                       (:todo "WAIT")
                                                       (:todo "RD")
                                                       (:todo "RDING")
                                                       (:todo "RDNOTE")
                                                       (:name "Important" :priority "A")
                                                       (:todo "TODO")
                                                       (:todo "GOAL")
                                                       (:discard (:todo "IDEA"))
                                                       (:discard (:todo "RD"))
                                                       (:discard (:todo "TMPDROP"))
                                                       (:discard (:todo "SOMEDAY"))
                                                       ))))))

                                     ("w" "Someday and Idea"
                                      ((alltodo "" ((org-agenda-overriding-header "")
                                                    (org-super-agenda-groups
                                                     '(
                                                       (:todo "IDEA")
                                                       (:todo "SOMEDAY")
                                                       (:discard (:todo "PROJ"))
                                                       (:discard (:todo "PROG"))
                                                       (:discard (:todo "NEXT"))
                                                       (:discard (:todo "WAIT"))
                                                       (:discard (:todo "RDNOTE"))
                                                       (:discard (:todo "RD"))
                                                       (:discard (:todo "RDING"))
                                                       (:discard (:todo "TODO"))
                                                       (:discard (:todo "GOAL"))
                                                       )
                                                     )))))))


  :config
  (org-super-agenda-mode))

;; Org Roam
(use-package! org-roam
  :commands (org-roam-insert org-roam-find-file org-roam)
  :init
  (setq org-roam-directory (concat org-directory "roam"))
  (setq org-roam-buffer-width 0.2)
  (map! :leader
        :prefix "n"
        :desc "Org-Roam-Insert" "i" #'org-roam-insert
        :desc "Org-Roam-Find"   "/" #'org-roam-find-file
        :desc "Org-Roam-Buffer" "r" #'org-roam)
  )


;; Attempt to remove lag
(setq key-chord-two-keys-delay 0.7)

(after! org (load! "org-conf.el"))

;; Better window management
(map! :map evil-window-map
      "SPC" #'rotate-layout
      ;; Navigation
      "<left>"     #'evil-window-left
      "<down>"     #'evil-window-down
      "<up>"       #'evil-window-up
      "<right>"    #'evil-window-right
      ;; Swapping windows
      "C-<left>"       #'+evil/window-move-left
      "C-<down>"       #'+evil/window-move-down
      "C-<up>"         #'+evil/window-move-up
      "C-<right>"      #'+evil/window-move-right)

(after! company
  (setq company-idle-delay 0.2
        company-minimum-prefix-length 2))

(after! evil-escape (evil-escape-mode -1))
(after! evil (setq evil-ex-substitute-global t)) ; I like my s/../.. to by global by default

(setq emojify-emoji-set "twemoji-v2")

(setq-default history-length 1000)
(setq-default prescient-history-length 1000)

(set-company-backend!
  '(text-mode
    markdown-mode
    gfm-mode)
  '(:seperate
    company-ispell
    company-files
    company-yasnippet))

(setq
        default-directory "~"
        web-mode-markup-indent-offset 4
        ispell-dictionary "en-custom"
        web-mode-code-indent-offset 4
        web-mode-css-indent-offset 4
        js-indent-level 4
        json-reformat:indent-width 4
        prettier-js-args '("--single-quote")
        projectile-project-search-path '("~/Projects/")
        dired-dwim-target t
        nand-hdl-directory "~/Projects/nand2tetris"
        css-indent-offset 2)


(setq auth-sources
    '((:source "~/.config/emacs/.authinfo.gpg")))

(defun insert-current-date () (interactive)
        (insert (shell-command-to-string "echo -n $(date +%Y-%m-%d)")))

;; We expect the encoding to be LF UTF-8, so only show the modeline when this is not the case
(defun doom-modeline-conditional-buffer-encoding ()
        (setq-local doom-modeline-buffer-encoding
                (unless (and (memq (plist-get (coding-system-plist buffer-file-coding-system) :category)
                        '(coding-category-undecided coding-category-utf-8))
                (not (memq (coding-system-eol-type buffer-file-coding-system) '(1 2))))
t)))

(add-hook 'after-change-major-mode-hook #'doom-modeline-conditional-buffer-encoding)



(map! :ne "M-/" #'comment-or-uncomment-region)
(map! :ne "SPC / r" #'deadgrep)
(map! :ne "SPC n b" #'org-brain-visualize)
(map! :ne "SPC i d" #'insert-current-date)

;; zoom in/out like we do everywhere else.
(global-set-key (kbd "C-=") 'text-scale-increase)
(global-set-key (kbd "C--") 'text-scale-decrease)
(global-set-key (kbd "<C-wheel-down>") 'text-scale-decrease)
(global-set-key (kbd "<C-wheel-up>") 'text-scale-increase)

(setq +magit-hub-features t)

(setq calc-angle-mode 'rad  ; radians are rad
      calc-symbolic-mode t) ; keeps expressions like \sqrt{2} irrational for as long as possible

(use-package! calctex
  :commands calctex-mode
  :init
  (add-hook 'calc-mode-hook #'calctex-mode)
  :config
  (setq calctex-additional-latex-packages "
\\usepackage[usenames]{xcolor}
\\usepackage{soul}
\\usepackage{adjustbox}
\\usepackage{amsmath}
\\usepackage{amssymb}
\\usepackage{siunitx}
\\usepackage{cancel}
\\usepackage{mathtools}
\\usepackage{mathalpha}
\\usepackage{xparse}
\\usepackage{arevmath}"
        calctex-additional-latex-macros
        (concat calctex-additional-latex-macros
                "\n\\let\\evalto\\Rightarrow"))
  (defadvice! no-messaging-a (orig-fn &rest args)
    :around #'calctex-default-dispatching-render-process
    (let ((inhibit-message t) message-log-max)
      (apply orig-fn args)))
  ;; Fix hardcoded dvichop path (whyyyyyyy)
  (let ((vendor-folder (concat (file-truename doom-local-dir)
                               "straight/"
                               (format "build-%s" emacs-version)
                               "/calctex/vendor/")))
    (setq calctex-dvichop-sty (concat vendor-folder "texd/dvichop")
          calctex-dvichop-bin (concat vendor-folder "texd/dvichop")))
  (unless (file-exists-p calctex-dvichop-bin)
    (message "CalcTeX: Building dvichop binary")
    (let ((default-directory (file-name-directory calctex-dvichop-bin)))
      (call-process "make" nil nil nil))))

(defun greedily-do-daemon-setup ()
  (require 'org)
  (when (require 'elfeed nil t)
    (run-at-time nil (* 8 60 60) #'elfeed-update)))

;; Open new clients in the dashboard
(when (daemonp)
  (add-hook 'emacs-startup-hook #'greedily-do-daemon-setup)
  (add-hook! 'server-after-make-frame-hook (switch-to-buffer +doom-dashboard-name)))

(set-popup-rule! "^\\*Org Agenda" :side 'bottom :size 0.90 :select t :ttl nil)
(set-popup-rule! "^\\*org-brain" :side 'right :size 1.00 :select t :ttl nil)

(sp-local-pair
 '(org-mode)
 "<<" ">>"
 :actions '(insert))

(setq +zen-text-scale 0.8)


(use-package! lexic
  :commands lexic-search lexic-list-dictionary
  :config
  (map! :map lexic-mode-map
        :n "q" #'lexic-return-from-lexic
        :nv "RET" #'lexic-search-word-at-point
        :n "a" #'outline-show-all
        :n "h" (cmd! (outline-hide-sublevels 3))
        :n "o" #'lexic-toggle-entry
        :n "n" #'lexic-next-entry
        :n "N" (cmd! (lexic-next-entry t))
        :n "p" #'lexic-previous-entry
        :n "P" (cmd! (lexic-previous-entry t))
        :n "E" (cmd! (lexic-return-from-lexic) ; expand
                     (switch-to-buffer (lexic-get-buffer)))
        :n "M" (cmd! (lexic-return-from-lexic) ; minimise
                     (lexic-goto-lexic))
        :n "C-p" #'lexic-search-history-backwards
        :n "C-n" #'lexic-search-history-forwards
        :n "/" (cmd! (call-interactively #'lexic-search))))

(defadvice! +lookup/dictionary-definition-lexic (identifier &optional arg)
  :override #'+lookup/dictionary-definition
  (interactive
   (list (or (doom-thing-at-point-or-region 'word)
             (read-string "Look up in dictionary: "))
         current-prefix-arg))
  (lexic-search identifier nil nil t))

;; Hooks
(add-hook 'nand-hdl-mode-hook 'yas-minor-mode)

(defun after-org-mode-load ()
  (interactive)
  (setq olivetti-body-width 0.8)
  (olivetti-mode)
  )
(add-hook! 'org-mode-hook 'after-org-mode-load)

;; Auto-Insert
(autoload 'yas-expand-snippet "yasnippet")
(defun my-autoinsert-yas-expand()
  "Replace text in yasnippet template."
  (yas-expand-snippet (buffer-string) (point-min) (point-max)))

(setq-default auto-insert-directory "~/.config/doom/templates")
(auto-insert-mode 1)  ;;; Adds hook to find-files-hook
(setq-default auto-insert-query nil) ;;; If you don't want to be prompted before insertion
(define-auto-insert "\\.el$" ["template.el" my-autoinsert-yas-expand])
(define-auto-insert "\\.c$"  ["template.c" my-autoinsert-yas-expand])
(define-auto-insert "\\.cpp$" ["template.cpp" my-autoinsert-yas-expand])
(define-auto-insert "\\.h$" ["template.h" my-autoinsert-yas-expand])
(define-auto-insert "\\.cc$" ["template.cpp" my-autoinsert-yas-expand])
(define-auto-insert "\\.tex$" ["template.tex" my-autoinsert-yas-expand])
(define-auto-insert "\\.org$" ["template.org" my-autoinsert-yas-expand])
(define-auto-insert "\\.py$" ["template.py" my-autoinsert-yas-expand])
(define-auto-insert "\\.java$" ["template.java" my-autoinsert-yas-expand])
(define-auto-insert "\\.sh$" ["template.sh" my-autoinsert-yas-expand])
(define-auto-insert "\\.html$" ["template.html" my-autoinsert-yas-expand])

(setq yas-snippet-dirs
      '("~/.config/doom/snippets"))

;; Appearance
(delq! t custom-theme-load-path) ;; Don't prompt on startup
(setq doom-theme 'doom-material-ocean)
(setq
        doom-big-font (font-spec :family "CasaydiaCove Nerd Font" :size 22)
        doom-font (font-spec :family "CaskaydiaCove Nerd Font" :size 16)
        doom-variable-pitch-font (font-spec :family "Overpass" :size 16)
        doom-unicode-font (font-spec :family "JuliaMono")
        doom-serif-font (font-spec :family "IBM Plex Mono" :weight 'light))

(setq +doom-dashboard-banner-file (expand-file-name "logo.png" doom-private-dir))

