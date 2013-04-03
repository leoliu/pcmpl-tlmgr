;;; pcmpl-tlmgr.el --- completion for tlmgr     -*- lexical-binding: t; -*-

;; Copyright (C) 2013  Leo Liu

;; Author: Leo Liu <sdl.web@gmail.com>
;; Version: 1.0
;; Keywords: tools, processes, convenience
;; Created: 2013-04-02

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

;; Completion for tlmgr - the TeX Live Manager.

;;; Code:

(eval-when-compile (require 'cl))
(require 'pcomplete)

(defcustom pcmpl-tlmgr-program "tlmgr"
  "Name of the tlmgr program."
  :type 'file
  :group 'pcomplete)

(defvar pcmpl-tlmgr-common-options
  '("--repository"
    "--gui"
    "--gui-lang"
    "--machine-readable"
    "--package-logfile"
    "--pause"
    "--persistent-downloads"
    "--no-persistent-downloads"
    "--no-execute-actions"
    "--debug-translation"
    "--help"
    "--version"))

(defvar pcmpl-tlmgr-actions
  '(("help")
    ("version")
    ("gui")
    ("install")
    ("update")
    ("backup")
    ("restore")
    ("remove")
    ("repository" ("list" "add" "remove" "set"))
    ("candidates")
    ("option" ("show"
               "showall"
               "repository"
               "formats"
               "postcode"
               "docfiles"
               "srcfiles"
               "backupdir"
               "autobackup"
               "sys_bin"
               "sys_man"
               "sys_info"
               "desktop_integration"
               "fileassocs"
               "multiuser"))
    ("conf" ("texmf" "tlmgr"))
    ("paper"
     ("a4" "letter" "xdvi" "pdftex" "dvips" "dvipdfmx" "dvipdfm" "context")
     (lambda ()
       (unless (member (pcomplete-arg 1) '("a4" "letter"))
         (pcomplete-here* '("paper"))
         (pcomplete-here* '("a4" "letter")))))
    ("platform" ("list" "add" "remove"))
    ("print-platform" ("collections" "schemes"))
    ("arch" ("list" "add" "remove"))
    ("print-arch" ("collections" "schemes"))
    ("info" ("collections" "schemes"))
    ("search")
    ("dump-tlpdb")
    ("check" ("files" "depends" "executes" "runfiles" "all"))
    ("path" ("add" "remove"))
    ("postaction" ("install" "remove") ("shortcut" "fileassoc" "script"))
    ("uninstall")
    ("generate" ("language"
                 "language.dat"
                 "language.def"
                 "language.dat.lua"
                 "fmtutil"))))

(defvar pcmpl-tlmgr-options-cache (make-hash-table :size 31 :test 'equal))

(defun pcmpl-tlmgr-action-options (action)
  "Get the list of long options for ACTION."
  (if (eq (gethash action pcmpl-tlmgr-options-cache 'missing) 'missing)
      (with-temp-buffer
        (when (zerop (call-process pcmpl-tlmgr-program nil t nil action "-h"))
          (goto-char (point-min))
          (puthash action
                   (cons "--help"
                         (loop while (re-search-forward
                                      "^[ \t]+\\(--[[:alnum:]-]+=?\\)" nil t)
                               collect (match-string 1)))
                   pcmpl-tlmgr-options-cache)
          (pcmpl-tlmgr-action-options action)))
    (gethash action pcmpl-tlmgr-options-cache)))

;;;###autoload
(defun pcomplete/tlmgr ()
  "Completion for the `tlmgr' command."
  (while (pcomplete-match "^--" 0)
    (pcomplete-here* pcmpl-tlmgr-common-options)
    (unless (or (pcomplete-match "^--" 0)
                (all-completions (pcomplete-arg 0) pcmpl-tlmgr-actions))
      (pcomplete-here* (pcomplete-dirs-or-entries))))
  (pcomplete-here* pcmpl-tlmgr-actions)
  (let ((action (substring-no-properties (pcomplete-arg 1))))
    (while t
      (if (pcomplete-match "^--" 0)
          (pcomplete-here* (pcmpl-tlmgr-action-options action))
        (dolist (completions (cdr (assoc action pcmpl-tlmgr-actions)))
          (cond ((functionp completions)
                 (funcall completions))
                ((all-completions (pcomplete-arg 0) completions)
                 (pcomplete-here* completions))
                (t (pcomplete-here* (pcomplete-dirs-or-entries)))))
        (unless (pcomplete-match "^--" 0)
          (pcomplete-here* (pcomplete-dirs-or-entries)))))))

(provide 'pcmpl-tlmgr)
;;; pcmpl-tlmgr.el ends here
