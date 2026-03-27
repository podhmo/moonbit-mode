;;; test/test-moonbit-mode.el --- ERT tests for moonbit-mode  -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; Font-lock and defun-name tests for moonbit-mode.
;; Uses ert-font-lock to validate annotated files under test/testdata/.
;;
;; Requirements:
;;   - Emacs 30+  + tree-sitter MoonBit grammar installed (tree-sitter's ABI version is 15)
;;   - ert-font-lock (bundled with Emacs 30+; install via package-install on Emacs 29)
;;
;; Run from the project root:
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
  "Root directory of the moonbit-mode project.")

;; Install grammar from local source under refs/ (no network required).
;; When a local directory is given as the URL, treesit skips git clone and
;; compiles <url>/src/parser.c directly into ~/.emacs.d/tree-sitter/.
(unless (treesit-language-available-p 'moonbit)
  (let ((local-repo (expand-file-name "refs/moonbitlang/tree-sitter-moonbit"
                                      moonbit-mode-test--root)))
    (when (file-directory-p local-repo)
      (add-to-list 'treesit-language-source-alist
                   `(moonbit ,local-repo))
      (treesit-install-language-grammar 'moonbit))))

;;; Helpers

(defun moonbit-mode-test--example (filename)
  "Return the absolute path to test/testdata/FILENAME."
  (expand-file-name (concat "test/testdata/" filename)
                    moonbit-mode-test--root))

(defmacro moonbit-mode-test--with-level4 (&rest body)
  "Execute BODY with treesit-font-lock-level set to 4 (all features enabled)."
  `(let ((treesit-font-lock-level 4))
     ,@body))

;;; Font-lock tests

(ert-deftest moonbit-mode-font-lock-mbt ()
  "Validate ert-font-lock annotations in font-lock.mbt."
  (skip-unless (treesit-ready-p 'moonbit t))
  (moonbit-mode-test--with-level4
   (ert-font-lock-test-file
    (moonbit-mode-test--example "font-lock.mbt")
    'moonbit-mode)))

(ert-deftest moonbit-mode-font-lock-mbti ()
  "Validate ert-font-lock annotations in font-lock.mbti."
  (skip-unless (treesit-ready-p 'moonbit t))
  (moonbit-mode-test--with-level4
   (ert-font-lock-test-file
    (moonbit-mode-test--example "font-lock.mbti")
    'moonbit-mode)))

(ert-deftest moonbit-mode-font-lock-moon-pkg ()
  "Validate ert-font-lock annotations in moon.pkg."
  (skip-unless (treesit-ready-p 'moonbit t))
  (moonbit-mode-test--with-level4
   (ert-font-lock-test-file
    (moonbit-mode-test--example "moon.pkg")
    'moonbit-mode)))

;;; defun-name tests

(defun moonbit-mode-test--find-node-by-type (type)
  "Return the first node of TYPE in the current buffer."
  (treesit-search-subtree
   (treesit-buffer-root-node)
   (lambda (node) (string= (treesit-node-type node) type))))

(defmacro moonbit-mode-test--with-defun-name (code node-type expected)
  "Insert CODE into a moonbit-mode buffer and verify that the defun name of the first NODE-TYPE node equals EXPECTED."
  `(progn
     (skip-unless (treesit-ready-p 'moonbit t))
     (with-temp-buffer
       (insert ,code)
       (moonbit-mode)
       (let ((node (moonbit-mode-test--find-node-by-type ,node-type)))
         (should node)
         (should (equal (moonbit--treesit-defun-name node) ,expected))))))

(ert-deftest moonbit-mode-defun-name-fn-simple ()
  "Defun name of a simple function without type parameters."
  (moonbit-mode-test--with-defun-name
   "fn greet(name : String) -> String { name }"
   "function_definition" "greet"))

(ert-deftest moonbit-mode-defun-name-fn-method ()
  "Defun name of a type method definition (Type::method)."
  (moonbit-mode-test--with-defun-name
   "fn Environment::new() -> Environment { { bindings: Map::new(), eval_count: 0 } }"
   "function_definition" "Environment::new"))

(ert-deftest moonbit-mode-defun-name-fn-generic ()
  "Defun name of a generic function with one type parameter."
  (moonbit-mode-test--with-defun-name
   "fn[T] identity(x : T) -> T { x }"
   "function_definition" "identity[T]"))

(ert-deftest moonbit-mode-defun-name-fn-generic-multi ()
  "Defun name of a generic function with multiple type parameters."
  (moonbit-mode-test--with-defun-name
   "fn[T, U, E] result_map(result : Result[T, E], f : (T) -> U) -> Result[U, E] { match result { Ok(v) => Ok(f(v)); Err(e) => Err(e) } }"
   "function_definition" "result_map[T, U, E]"))

(ert-deftest moonbit-mode-defun-name-struct-simple ()
  "Defun name of a simple struct definition."
  (moonbit-mode-test--with-defun-name
   "struct Foo { x : Int }"
   "struct_definition" "Foo"))

(ert-deftest moonbit-mode-defun-name-struct-generic ()
  "Defun name of a generic struct definition."
  (moonbit-mode-test--with-defun-name
   "struct Pair[T] { first : T; second : T }"
   "struct_definition" "Pair[T]"))

(ert-deftest moonbit-mode-defun-name-enum ()
  "Defun name of an enum definition."
  (moonbit-mode-test--with-defun-name
   "enum Color { Red; Green; Blue }"
   "enum_definition" "Color"))

(ert-deftest moonbit-mode-defun-name-trait ()
  "Defun name of a trait definition."
  (moonbit-mode-test--with-defun-name
   "trait Show { to_string(Self) -> String }"
   "trait_definition" "Show"))

(ert-deftest moonbit-mode-defun-name-error-type ()
  "Defun name of a suberror type definition."
  (moonbit-mode-test--with-defun-name
   "suberror EvalError { DivByZero }"
   "error_type_definition" "EvalError"))

(ert-deftest moonbit-mode-defun-name-const ()
  "Defun name of a constant definition."
  (moonbit-mode-test--with-defun-name
   "const MAX_SIZE : Int = 100"
   "const_definition" "MAX_SIZE"))

(ert-deftest moonbit-mode-defun-name-test-named ()
  "Defun name of a named test definition."
  (moonbit-mode-test--with-defun-name
   "test \"my test\" { let x = 1 }"
   "test_definition" "\"my test\""))

(ert-deftest moonbit-mode-defun-name-test-anonymous ()
  "Defun name of an anonymous test definition is <anonymous test>."
  (moonbit-mode-test--with-defun-name
   "test { let x = 1 }"
   "test_definition" "<anonymous test>"))

(ert-deftest moonbit-mode-defun-name-impl ()
  "Defun name of an impl definition in Trait for Type::method form."
  (moonbit-mode-test--with-defun-name
   "impl Show for Expression with to_string(self) { \"\" }"
   "impl_definition" "Show for Expression::to_string"))

(ert-deftest moonbit-mode-defun-name-impl-generic ()
  "Defun name of a generic impl definition."
  (moonbit-mode-test--with-defun-name
   "impl[T : Show] Show for Array[T] with to_string(self) { \"\" }"
   "impl_definition" "Show for Array[T]::to_string"))

;;; auto-mode-alist tests

(ert-deftest moonbit-mode-auto-mode-mbt ()
  "Verify that moonbit-mode activates for .mbt files."
  (let ((buf (find-file-noselect
              (moonbit-mode-test--example "font-lock.mbt"))))
    (unwind-protect
        (with-current-buffer buf
          (should (eq major-mode 'moonbit-mode)))
      (kill-buffer buf))))

(ert-deftest moonbit-mode-auto-mode-mbti ()
  "Verify that moonbit-mode activates for .mbti files."
  (let ((buf (find-file-noselect
              (moonbit-mode-test--example "font-lock.mbti"))))
    (unwind-protect
        (with-current-buffer buf
          (should (eq major-mode 'moonbit-mode)))
      (kill-buffer buf))))

(ert-deftest moonbit-mode-auto-mode-moon-pkg ()
  "Verify that moonbit-mode activates for moon.pkg files."
  (let ((buf (find-file-noselect
              (moonbit-mode-test--example "moon.pkg"))))
    (unwind-protect
        (with-current-buffer buf
          (should (eq major-mode 'moonbit-mode)))
      (kill-buffer buf))))

(provide 'test-moonbit-mode)

;;; test/test-moonbit-mode.el ends here

