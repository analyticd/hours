;;; jobhours --- Companion code for the 'hours' Haskell utility

;; Copyright (C) 2018 John Wiegley

;; Author: John Wiegley <johnw@newartisans.com>
;; Created: 12 Dec 2012
;; Version: 3.0
;; Keywords: hours
;; X-URL: https://github.com/jwiegley/hours

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2, or (at
;; your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; This code calls out to the 'hours' utility and provides a UI display.

(defgroup jobhours nil
  "Companion code for the 'hours' Haskell utility"
  :group 'jobhours)

(defcustom jobhours-files '("todo.txt")
  "The Org-file from which time clock data is read.
Note that the 'org2tc' utility must be on your PATH."
  :type '(repeat file)
  :group 'jobhours)

(defvar jobhours-display-total-string nil
  "If non-nil then show both the stats for the current day and the current
month periods.")

(defun jobhours-toggle-display-format ()
  "Toggle between the display of short or long format jobhours-string."
  (interactive)
  (setq jobhours-display-total-string (not jobhours-display-total-string)))

(defun jobhours-get-string (&optional show-all)
  (with-temp-buffer
    (apply #'call-process "jobhours" nil t nil
           (mapcar #'expand-file-name jobhours-files))

    (goto-char (point-min))
    (let* ((details (read (current-buffer)))
           (logged-in            (alist-get 'logged-in details))
           (ideal-progress       (alist-get 'ideal-progress details))
           (display-string       (alist-get 'display-string details))
           (total-string         (alist-get 'total-string details))
           (text-color           (apply #'color-rgb-to-hex
                                        (alist-get 'text-color details)))
           (progress-color       (apply #'color-rgb-to-hex
                                        (alist-get 'progress-color details)))

           (properties (lambda (back)
                         (list :foreground text-color
                               :background back
                               :weight (if logged-in 'bold 'light)))))

      (delete-region (point-min) (point-max))

      (insert "  "
              (if show-all
                  (concat display-string "  ─  " total-string)
                (if logged-in
                    display-string
                  total-string)) "  ")

      ;; Color the whole "time bar" a neutral, light grey
      (add-face-text-property (point-min) (point-max)
                              (funcall properties "grey75"))

      ;; Darken a percentage of the bar, starting from the right, to show what
      ;; percentage of the time period has been worked. Color it based on the
      ;; current progress.
      (add-face-text-property
       (max 1 (- (point-max) (floor (* (point-max) ideal-progress))))
       (point-max) (funcall properties progress-color))

      (buffer-string))))

(defvar jobhours-string "")
(put 'jobhours-string 'risky-local-variable t)

(defun jobhours-update-string ()
  (interactive)
  (setq jobhours-string
        (jobhours-get-string jobhours-display-total-string)))

(defun jobhours-setup-modeline ()
  (run-at-time 0 300 #'jobhours-update-string)
  (push " " (default-value 'mode-line-format))
  (push '(:eval jobhours-string) (default-value 'mode-line-format)))

(provide 'jobhours)
