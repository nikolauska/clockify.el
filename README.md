# Clockify.el

An emacs plugin for https://clockify.me

## Install

Add this to your config file

``` emacs-lisp
(use-package clockify
  :load-path "~/projects/clockify.el"
  :config
  (setq clockify-api-key "<api-key>")
  (setq clockify-user-id "<user-id>")
  (setq clockify-workspace "<workspace-id>"))
```

### Doom emacs

```emacs-lisp
;; In packages.el
(package! clockify
  :recipe (:host github :repo "nikolauska/clockify.el" :files ("*.el")))

;; In config.el
(use-package clockify
  :init
  (map! :localleader
        :n
        :desc "Start timer"          "k" #'clockify-start
        :desc "Stop timer"          "l" #'clockify-stop)
  :config
  (setq clockify-api-key "<api-key>")
  (setq clockify-user-id "<user-id>")
  (setq clockify-workspace "<workspace-id>"))
```
