;; This code provide functions needed for erlang-flymake.el present in
;; OTP from 14 something and onward.
;;
;; It traverses the directory hierarchy N steps down and looks for
;; include and ebin directories to feed to the erlang compiler.
;;
;; To use this add something like this to your emacs configuration:
;;
;; (defun flymake-erlang-load-hook ()
;;   (require 'erlang-flymaker-el)
;;   (flymake-mode))
;;
;; (add-hook 'erlang-mode-hook 'flymake-erlang-load-hook)

(require 'erlang-flymake)

(defvar flymaker--default-depth 3
  "Default depth to go down the directory structure.")

(defun flymaker--compose-offset-string (str depth)
  "Pass in '../' and a 3 and get '../../../' back."
  (let ((result nil))
    (dotimes (n depth result)
      (setq result (concat str result)))))

(defun flymaker--get-relevant-dirs (paths regex)
  "Takes a list of paths and returns subdirs in each path that
matches regex."
  (dolist (path paths)
    (nconc (directory-files path t regex))))

(defun flymaker--traverse-tree (directory match-regex depth)
  "Recursively looks through a directory `depth' levels down and
returns a list of all found dirs."
  (let ((offset (flymaker--compose-offset-string "../" depth)))
    (flymaker--traverse-tree-helper
     (directory-files (file-name-as-directory
                       (concat directory offset)) t) match-regex depth 0)))

(defun flymaker--traverse-tree-helper (directories regex depth current-depth)
  (when (> depth current-depth)
    (let ((nextdirs nil))
      (dolist (dir directories)
        (when (and (file-directory-p dir)
                   (not (string-match "\\(\\.\\|\\.\\.\\)"
                                      (file-name-nondirectory dir))))
          (setq nextdirs (nconc nextdirs (list dir)))))
      (flymaker--traverse-tree-helper
       nextdirs regex depth (1+ current-depth)))))

(defun* flymaker--get-dir-of-buffer (&optional (buffer (current-buffer)))
  "Return the dir the buffers visiting file is in."
  (file-name-directory (file-truename (buffer-file-name buffer))))

(defun flymaker--get-paths (name depth)
  (let* ((base-dir (flymaker--get-dir-of-buffer))
         (all-dirs (flymaker--traverse-tree base-dir name depth)))
    (flymaker--get-relevant-dirs all-dirs (concat name "$"))))

(defun flymaker--find-code-paths ()
  (mapcar (lambda (dir) (file-name-as-directory dir))
          (flymaker--get-paths "ebin" flymaker--default-depth)))

(defun flymaker--find-includes ()
  (mapcar (lambda (dir) (file-name-as-directory dir))
          (flymaker--get-paths "include" flymaker--default-depth)))

(setq erlang-flymake-get-code-path-dirs-function 'flymaker--find-code-paths)
(setq erlang-flymake-get-include-dirs-function 'flymaker--find-includes)

(provide 'erlang-flymaker-el)
