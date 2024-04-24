;;; clockify.el --- Clockify time tracking -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2024 nikolauska
;;
;; Author: Nikolauska <nikolauska1@gmail.com>
;; Version: 0.1.0
;; Homepage: https://github.com/nikolauska/clockify.el
;; Package-Requires: ((emacs "26.3"))
;;
;; This file is not part of GNU Emacs.
;;
;; clockify.el is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; clockify.el is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with clockify.el.
;; If not, see <https://www.gnu.org/licenses/>.
;;
;;; Commentary:
;;
;; This package provides a simple interface to the Clockify API.
;;
;;; Code:

(require 'json)
(require 'request)

(defgroup clockify nil
  "Elisp library for the Clockify API."
  :prefix "clockify-"
  :group 'comm
  :link '(url-link :tag "Repository" "https://github.com/nikolauska/clockify.el"))

(defvar clockify-api-key "Clockify API key.")
(defvar clockify-user-id "Clockify user id.")
(defvar clockify-workspace "Clockify workspace id.")

(defvar clockify-error nil
  "Records for the last error.")

;;;###autoload
(define-minor-mode clockify-debug-mode
  "Turn on/off debug mode for `clockify'."
  :group 'clockify
  :global t
  :init-value nil)

(defun clockify--log (fmt &rest args)
  "Debug message like function `message' with same argument FMT and ARGS."
  (when clockify-debug-mode
    (apply 'message fmt args)))

(defun clockify--json-encode (object)
  "Wrapper for function `json-encode'.

  The argument OBJECT is an alist that can be construct to JSON data;
  see function `json-encode' for the detials."
  (let ((encoded (json-encode object)))
    (clockify--log "[ENCODED]: %s" encoded)
    encoded))

(defun clockify--handle-error (response)
  "Handle error status code from the RESPONSE."
  (let ((status-code (request-response-status-code response)))
    (clockify--log "[ERROR]: %s" response)
    (pcase status-code
      (400 (message "400 - Bad request.  Please check error message and your parameters"))
      (401 (message "401 - Invalid Authentication"))
      (403 (message "403 - Invalid Authentication"))
      (404 (message "404 - Not found"))
      (429 (message "429 - Rate limit reached for requests"))
      (500 (message "500 - The server had an error while processing your request"))
      (_   (message "Internal error: %s" status-code)))))

(defun clockify--request (method path &optional body)
  "Wrapper for `request' function.

  The PATH is the url for `request' function; METHOD is
  the request type and then BODY is the arguments for rest."
  (setq clockify-error nil)
  (let ((response (request-response-data
                   (request (concat "https://api.clockify.me/api/v1" path)
                     :headers `(("Content-Type" . "application/json")
                                ("X-Api-Key" . ,clockify-api-key))
                     :type method
                     :sync t
                     :parser 'json-read
                     :data (clockify--json-encode body)
                     :error (cl-function
                             (lambda (&key response &allow-other-keys)
                               (setq clockify-error response)
                               (clockify--handle-error response)))))))
    response))

(defun clockify--select-project (projects)
  "Select a project from the list of provided PROJECTS."
  (interactive)
  (let ((project (completing-read
                  "Choose clockify project: "
                  (mapcar (lambda (project)
                            (concat
                             (nth 2 project)
                             " - "
                             (nth 0 project)
                             " / "
                             (nth 1 project)))
                          projects))))
    (car (split-string project "\s"))))

(defun clockify--get-projects ()
  "Get all clockify projects."
  (interactive)
  (clockify--log "Getting all clockify projects...")
  (let ((page 1)
        (page-size 5000)
        (break nil)
        (clockify-projects '()))
    (while (not break)
      (clockify--log (format "Fetching page: %d" page))
      (let* ((params (format "?page=%d&page-size=%d" page page-size))
             (projects (clockify--request "GET" (concat "/workspaces/" clockify-workspace "/projects" params))))
        (progn
          (clockify--log (format "Total projects fetched: %d" (length clockify-projects)))
          (setq clockify-projects (vconcat clockify-projects projects))
          (setq page (+ page 1))
          (when (< (length projects) page-size)
            (setq break t)))))
    (clockify--log "Done. Fetched all clockify data.")
    (mapcar (lambda (project)
              (let ((clientName (cdr (assoc 'clientName project)))
                    (name (cdr (assoc 'name project)))
                    (id (cdr (assoc 'id project))))
                (list clientName name id)))
            clockify-projects)))

(defun clockify-start ()
  "Start a clockify time entry for the selected project."
  (interactive)
  (clockify--request "POST" (concat "/workspaces/" clockify-workspace "/time-entries")
                     (list
                      (cons "start" (format-time-string "%Y-%m-%dT%TZ" (current-time) t))
                      (cons "projectId" (clockify--select-project (clockify--get-projects)))
                      (cons "description" (read-string "Description: ")))))

(defun clockify-stop ()
  "Stop a clockify time entry for the selected project."
  (interactive)
  (clockify--request "PATCH" (concat "/workspaces/" clockify-workspace "/user/" clockify-user-id "/time-entries")
                     (list
                      (cons "end" (format-time-string "%Y-%m-%dT%TZ" (current-time) t)))))

(provide 'clockify)
;;; clockify.el ends here
