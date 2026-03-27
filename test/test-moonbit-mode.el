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

;;; defun-name テスト

(defun moonbit-mode-test--find-node-by-type (type)
  "カレントバッファから最初の TYPE ノードを返す。"
  (treesit-search-subtree
   (treesit-buffer-root-node)
   (lambda (node) (string= (treesit-node-type node) type))))

(defmacro moonbit-mode-test--with-defun-name (code node-type expected)
  "CODE を moonbit-mode バッファに入れ、NODE-TYPE の defun 名が EXPECTED と等しいか検証する。"
  `(progn
     (skip-unless (treesit-ready-p 'moonbit t))
     (with-temp-buffer
       (insert ,code)
       (moonbit-mode)
       (let ((node (moonbit-mode-test--find-node-by-type ,node-type)))
         (should node)
         (should (equal (moonbit--treesit-defun-name node) ,expected))))))

(ert-deftest moonbit-mode-defun-name-fn-simple ()
  "シンプルな関数の defun 名を検証する。"
  (moonbit-mode-test--with-defun-name
   "fn greet(name : String) -> String { name }"
   "function_definition" "greet"))

(ert-deftest moonbit-mode-defun-name-fn-method ()
  "型メソッド定義 (Type::method) の defun 名を検証する。"
  (moonbit-mode-test--with-defun-name
   "fn Environment::new() -> Environment { { bindings: Map::new(), eval_count: 0 } }"
   "function_definition" "Environment::new"))

(ert-deftest moonbit-mode-defun-name-fn-generic ()
  "型パラメーター 1 つの generic 関数の defun 名を検証する。"
  (moonbit-mode-test--with-defun-name
   "fn[T] identity(x : T) -> T { x }"
   "function_definition" "identity[T]"))

(ert-deftest moonbit-mode-defun-name-fn-generic-multi ()
  "型パラメーター複数の generic 関数の defun 名を検証する。"
  (moonbit-mode-test--with-defun-name
   "fn[T, U, E] result_map(result : Result[T, E], f : (T) -> U) -> Result[U, E] { match result { Ok(v) => Ok(f(v)); Err(e) => Err(e) } }"
   "function_definition" "result_map[T, U, E]"))

(ert-deftest moonbit-mode-defun-name-struct-simple ()
  "シンプルな struct の defun 名を検証する。"
  (moonbit-mode-test--with-defun-name
   "struct Foo { x : Int }"
   "struct_definition" "Foo"))

(ert-deftest moonbit-mode-defun-name-struct-generic ()
  "型パラメーター付き struct の defun 名を検証する。"
  (moonbit-mode-test--with-defun-name
   "struct Pair[T] { first : T; second : T }"
   "struct_definition" "Pair[T]"))

(ert-deftest moonbit-mode-defun-name-enum ()
  "enum の defun 名を検証する。"
  (moonbit-mode-test--with-defun-name
   "enum Color { Red; Green; Blue }"
   "enum_definition" "Color"))

(ert-deftest moonbit-mode-defun-name-trait ()
  "trait の defun 名を検証する。"
  (moonbit-mode-test--with-defun-name
   "trait Show { to_string(Self) -> String }"
   "trait_definition" "Show"))

(ert-deftest moonbit-mode-defun-name-error-type ()
  "suberror 型の defun 名を検証する。"
  (moonbit-mode-test--with-defun-name
   "suberror EvalError { DivByZero }"
   "error_type_definition" "EvalError"))

(ert-deftest moonbit-mode-defun-name-const ()
  "定数の defun 名を検証する。"
  (moonbit-mode-test--with-defun-name
   "const MAX_SIZE : Int = 100"
   "const_definition" "MAX_SIZE"))

(ert-deftest moonbit-mode-defun-name-test-named ()
  "名前付き test の defun 名を検証する。"
  (moonbit-mode-test--with-defun-name
   "test \"my test\" { let x = 1 }"
   "test_definition" "\"my test\""))

(ert-deftest moonbit-mode-defun-name-test-anonymous ()
  "匿名 test の defun 名が <anonymous test> になることを検証する。"
  (moonbit-mode-test--with-defun-name
   "test { let x = 1 }"
   "test_definition" "<anonymous test>"))

(ert-deftest moonbit-mode-defun-name-impl ()
  "impl の defun 名 (Trait for Type::method) を検証する。"
  (moonbit-mode-test--with-defun-name
   "impl Show for Expression with to_string(self) { \"\" }"
   "impl_definition" "Show for Expression::to_string"))

(ert-deftest moonbit-mode-defun-name-impl-generic ()
  "型パラメーター付き impl の defun 名を検証する。"
  (moonbit-mode-test--with-defun-name
   "impl[T : Show] Show for Array[T] with to_string(self) { \"\" }"
   "impl_definition" "Show for Array[T]::to_string"))

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
