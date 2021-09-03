;;; $DOOMDIR/org-conf.el -*- lexical-binding: t; -*-
;;; org-conf.el<2> --- Description

;; Author: Yigit Colakoglu  yigit@yigitcolakoglu.com

;; Copyright (C) Symbol’s value as variable is void: %Y, Yigit Colakoglu, all rights reserved.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;; This file contains the org-mode specific configuration for my emacs config
;;

;;; Code:
(setq org-export-with-section-numbers nil)

(setq org-agenda-files (directory-files org-directory t "\\.org$" t))

(setq org-display-remote-inline-images 'download)
(setq org-agenda-include-deadlines t)
(setq org-agenda-dim-blocked-tasks 'invisible)
(setq org-latex-packages-alist '(("margin=1in" "geometry" nil))) ;; adjusting the margins of latex output
(setq org-format-latex-options (plist-put org-format-latex-options :scale 2.5)) ;; making latex previews larger
(setq org-bullets-bullet-list '("·"))
(setq org-log-done 'time)
(setq org-tags-column -80)
(setq org-refile-targets (quote ((nil :maxlevel . 1))))

(setq org-todo-keywords '((sequence
                           "TODO"
                           "PROJ"
                           "NEXT(n)"
                           "PROG(p!)"
                           "WAIT(w@/!)"
                           "SOMEDAY"
                           "|"
                           "DONE(d)"
                           "CANCEL(c@)"
                           "DELEGATED(@)"
                           )
                          (sequence
                           "IDEA"
                           "GOAL"
                           "|"
                           "DUD(@)")
                          (sequence
                           "RD"
                           "RDING"
                           "RDNOTE"
                           "TMPDROP"
                           "|"
                           "DROP"
                           "FNSHED"
                           )
                          ))

(setq org-fancy-priorities-list '("⚡" "⬆" "⬇" "☕"))

(setq org-caldav-url "https://drive.yigitcolakoglu.com/remote.php/dav/calendars/yigitcolakoglu")
(setq org-icalendar-timezone "Europe/Istanbul")
(setq org-caldav-calendars
  '((:calendar-id "pcalendar" :files ("~/Documents/org/pcalendar.org")
     :inbox "~/.local/share/pcalendar.org")))

;; Mappings

(map! :ne "SPC m a c" #'org-insert-clipboard-image)

(map! :map calc-mode-map
      :after calc
      :localleader
      :desc "Embedded calc (toggle)" "e" #'calc-embedded)
(map! :map org-mode-map
      :after org
      :localleader
      :desc "Embedded calc (toggle)" "E" #'calc-embedded)
(map! :map latex-mode-map
      :after latex
      :localleader
      :desc "Embedded calc (toggle)" "e" #'calc-embedded)
(map! :map org-mode-map
      :after org
      :localleader
      :desc "Outline" "O" #'org-ol-tree)


;; Org Superstar
;;
(setq org-superstar-remove-leading-stars t)

(setq org-capture-templates
      `(
        ("t" "Todo" entry (file ,(concat org-directory "personal.org"))
         "* TODO %? \n%U" :empty-lines 1)
        ("d" "Todo deadline" entry (file ,(concat org-directory "personal.org"))
         "* TODO %? \nDEADLINE: %^T\n%U" :empty-lines 1)
        ("w" "Wait deadline" entry (file ,(concat org-directory "personal.org"))
         "* WAIT %? \nDEADLINE: %^T\n%U" :empty-lines 1)
        ("r" "Reading List" entry (file+olp ,(concat org-directory "reading_list.org") "Catchall")
         "* RD %? \n%U" :empty-lines 1)
        ("i" "Idea" entry (file ,(concat org-directory "personal.org"))
         "* IDEA %? \n%U" :empty-lines 1)
        ("s" "Someday" entry (file+olp ,(concat org-directory "someday.org") "Catchall")
         "* SOMEDAY %? \n%U" :empty-lines 1)
        ("e" "Event" entry (file ,(concat org-directory "personal.org"))
         "* %? \nSCHEDULED: %^T\n%U" :empty-lines 1)
        ("c" "Cookbook" entry (file ,(concat org-directory "cookbook.org"))
         "%(org-chef-get-recipe-from-url)" :empty-lines 1)
        ("C" "Manual Cookbook" entry (file ,(concat org-directory "cookbook.org"))
         "* %^{Recipe title: }\n  :PROPERTIES:\n  :source-url:\n  :servings:\n  :prep-time:\n  :cook-time:\n  :ready-in:\n  :END:\n** Ingredients\n   %?\n** Directions\n\n")
        ("j" "Journal entry" entry (function org-journal-find-location)
         "* NEXT %?\n%U" :empty-lines 1)
        ("k" "Journal sched entry" entry (function org-journal-find-location)
         "* %? %^T\n%U" :empty-lines 1)
        ("m" "Morning Journal entry" entry (function org-journal-find-location)
         "* Morning Entry
** Checklist

   - [ ] Make bed
   - [ ] Brush Teeth
   - [ ] Cook something nice
   - [ ] Read for 20 pages
   - [ ] Take note of things I am looking forward to in journal
   - [ ] Wash face
     - plan tips:
       - don't put mentally straining todos after working out or eating.
       - mentally chill stuff includes:
         - relaxing reading
         - article reading
** Looking Forward To %?
** Day Plan
** Determinations :determ:" :empty-lines 1)
        ("n" "Night Journal entry" entry (function org-journal-find-location)
         "* Today's Learnings\n* My Day\n%U")
        ))


;; Org Journal
(defun org-journal-find-location ()
  ;; Open today's journal, but specify a non-nil prefix argument in order to
  ;; inhibit inserting the heading; org-capture will insert the heading.
  (org-journal-new-entry t)
  ;; Position point on the journal's top-level heading so that org-capture
  ;; will add the new entry as a child entry.
  (goto-char (point-min)))


(set-face-attribute 'org-table nil :inherit 'fixed-pitch)

(set-face-attribute 'org-block nil :inherit 'fixed-pitch)

;; Refile taken from here: https://www.reddit.com/r/emacs/comments/4366f9/how_do_orgrefiletargets_work/
(setq org-refile-targets '((nil :maxlevel . 9)
                           (org-agenda-files :maxlevel . 9)))
(setq org-outline-path-complete-in-steps nil)         ; Refile in a single go
(setq org-refile-use-outline-path t)                  ; Show full paths for refiling
(setq org-refile-allow-creating-parent-nodes (quote confirm))
(setq org-pretty-entities t)

(setq org-hide-emphasis-markers t)
(setq org-fontify-whole-heading-line t)
(setq org-fontify-done-headline t)
(setq org-fontify-quote-and-verse-blocks t)
(setq org-tags-column 0)
(setq org-src-fontify-natively t)
(setq org-edit-src-content-indentation 0)
(setq org-src-tab-acts-natively t)
(setq org-src-preserve-indentation t)

(setq org-list-demote-modify-bullet '(("+" . "-") ("-" . "+") ("*" . "+") ("1." . "a.")))

(setq org-log-done 'time)

(provide 'org-conf.el)

;; Embedded Calc
(defvar calc-embedded-trail-window nil)
(defvar calc-embedded-calculator-window nil)

(defadvice! calc-embedded-with-side-pannel (&rest _)
  :after #'calc-do-embedded
  (when calc-embedded-trail-window
    (ignore-errors
      (delete-window calc-embedded-trail-window))
    (setq calc-embedded-trail-window nil))
  (when calc-embedded-calculator-window
    (ignore-errors
      (delete-window calc-embedded-calculator-window))
    (setq calc-embedded-calculator-window nil))
  (when (and calc-embedded-info
             (> (* (window-width) (window-height)) 1200))
    (let ((main-window (selected-window))
          (vertical-p (> (window-width) 80)))
      (select-window
       (setq calc-embedded-trail-window
             (if vertical-p
                 (split-window-horizontally (- (max 30 (/ (window-width) 3))))
               (split-window-vertically (- (max 8 (/ (window-height) 4)))))))
      (switch-to-buffer "*Calc Trail*")
      (select-window
       (setq calc-embedded-calculator-window
             (if vertical-p
                 (split-window-vertically -6)
               (split-window-horizontally (- (/ (window-width) 2))))))
      (switch-to-buffer "*Calculator*")
      (select-window main-window))))

;;; ol-man.el - Support for links to man pages in Org mode
;;; https://www.gnu.org/software/emacs/manual/html_node/org/Adding-Hyperlink-Types.html
(org-link-set-parameters "man"
                         :follow #'org-man-open
                         :export #'org-man-export
                         :store #'org-man-store-link)

(defcustom org-man-command 'man
  "The Emacs command to be used to display a man page."
  :group 'org-link
  :type '(choice (const man) (const woman)))

(defun org-man-open (path _)
  "Visit the manpage on PATH.
PATH should be a topic that can be thrown at the man command."
  (funcall org-man-command path))

(defun org-man-store-link ()
  "Store a link to a man page."
  (when (memq major-mode '(Man-mode woman-mode))
    ;; This is a man page, we do make this link.
    (let* ((page (org-man-get-page-name))
           (link (concat "man:" page))
           (description (format "Man page for %s" page)))
      (org-link-store-props
       :type "man"
       :link link
       :description description))))

(defun org-man-get-page-name ()
  "Extract the page name from the buffer name."
  ;; This works for both `Man-mode' and `woman-mode'.
  (if (string-match " \\(\\S-+\\)\\*" (buffer-name))
      (match-string 1 (buffer-name))
    (error "Cannot create link to this man page")))

(defun org-man-export (link description format _)
  "Export a man page link from Org files."
  (let ((path (format "http://man.he.net/?topic=%s&section=all" link))
        (desc (or description link)))
    (pcase format
      (`html (format "<a target=\"_blank\" href=\"%s\">%s</a>" path desc))
      (`latex (format "\\href{%s}{%s}" path desc))
      (`texinfo (format "@uref{%s,%s}" path desc))
      (`ascii (format "%s (%s)" desc path))
      (t path))))

;;; org-conf.el<2> ends here.
