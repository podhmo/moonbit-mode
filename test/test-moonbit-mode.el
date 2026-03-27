;;; test/test-moonbit-mode.el --- ERT tests for moonbit-mode  -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; moonbit-mode の font-lock テスト。
;; ert-font-lock を使用して examples/ 以下のアノテーション付きファイルを検証する。
;;
;; 必要条件:
;;   - Emacs 29+  + tree-sitter MoonBit 文法インストール済み
;;   - ert-font-lock (Emacs 30+ 標準, 29 以下は package-install 'ert-font-lock)
;;
;; 実行方法 (プロジェクトルートから):
;;
;;   emacs --batch \
;;     -l moonbit-mode.el \
;;     -l test/test-moonbit-mode.el \
;;     -f ert-run-tests-batch-and-exit
;;

;;; Code:

(require 'ert)
(require 'ert-font-lock)
(require 'moonbit-mode)

;;; Grammar installation

(defvar moonbit-mode-test--root
  (file-name-directory
   (directory-file-name
    (file-name-directory (or load-file-name buffer-file-name))))
  "moonbit-mode プロジェクトのルートディレクトリ。")

;; refs/ 以下のローカルソースから文法をインストール（ネットワーク不要）
;; URL にローカルディレクトリを指定すると url-is-dir=t となり git clone をスキップし、
;; <url>/src/parser.c をコンパイルして ~/.emacs.d/tree-sitter/ に配置する
(unless (treesit-language-available-p 'moonbit)
  (let ((local-repo (expand-file-name "refs/moonbitlang/tree-sitter-moonbit"
                                      moonbit-mode-test--root)))
    (when (file-directory-p local-repo)
      (add-to-list 'treesit-language-source-alist
                   `(moonbit ,local-repo))
      (treesit-install-language-grammar 'moonbit))))

;;; Helpers

(defun moonbit-mode-test--example (filename)
  "examples/FILENAME の絶対パスを返す。"
  (expand-file-name (concat "examples/" filename)
                    moonbit-mode-test--root))

(defmacro moonbit-mode-test--with-level4 (&rest body)
  "treesit-font-lock-level を 4 (全フィーチャ有効) にして BODY を実行する。"
  `(let ((treesit-font-lock-level 4))
     ,@body))

;;; font-lock テスト

(ert-deftest moonbit-mode-font-lock-mbt ()
  "font-lock.mbt のアノテーションを検証する。"
  (skip-unless (treesit-ready-p 'moonbit t))
  (moonbit-mode-test--with-level4
   (ert-font-lock-test-file
    (moonbit-mode-test--example "font-lock.mbt")
    'moonbit-mode)))

(ert-deftest moonbit-mode-font-lock-mbti ()
  "font-lock.mbti のアノテーションを検証する。"
  (skip-unless (treesit-ready-p 'moonbit t))
  (moonbit-mode-test--with-level4
   (ert-font-lock-test-file
    (moonbit-mode-test--example "font-lock.mbti")
    'moonbit-mode)))

(ert-deftest moonbit-mode-font-lock-moon-pkg ()
  "moon.pkg のアノテーションを検証する。"
  (skip-unless (treesit-ready-p 'moonbit t))
  (moonbit-mode-test--with-level4
   (ert-font-lock-test-file
    (moonbit-mode-test--example "moon.pkg")
    'moonbit-mode)))

;;; auto-mode-alist テスト

(ert-deftest moonbit-mode-auto-mode-mbt ()
  ".mbt ファイルで moonbit-mode が有効になることを確認する。"
  (let ((buf (find-file-noselect
              (moonbit-mode-test--example "font-lock.mbt"))))
    (unwind-protect
        (with-current-buffer buf
          (should (eq major-mode 'moonbit-mode)))
      (kill-buffer buf))))

(ert-deftest moonbit-mode-auto-mode-mbti ()
  ".mbti ファイルで moonbit-mode が有効になることを確認する。"
  (let ((buf (find-file-noselect
              (moonbit-mode-test--example "font-lock.mbti"))))
    (unwind-protect
        (with-current-buffer buf
          (should (eq major-mode 'moonbit-mode)))
      (kill-buffer buf))))

(ert-deftest moonbit-mode-auto-mode-moon-pkg ()
  "moon.pkg ファイルで moonbit-mode が有効になることを確認する。"
  (let ((buf (find-file-noselect
              (moonbit-mode-test--example "moon.pkg"))))
    (unwind-protect
        (with-current-buffer buf
          (should (eq major-mode 'moonbit-mode)))
      (kill-buffer buf))))

(provide 'test-moonbit-mode)

;;; test/test-moonbit-mode.el ends here
