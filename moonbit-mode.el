;;; moonbit-mode.el --- Tree-sitter support for MoonBit  -*- lexical-binding: t; -*-

;; Author: podhmo
;; Keywords: moonbit languages tree-sitter
;; Version: 0.1.0

;; This file is NOT part of GNU Emacs.

;;; Commentary:

;; `moonbit-mode' is a major mode for MoonBit source files (.mbt)
;; using Emacs's built-in tree-sitter support (Emacs 30+).
;;
;; Features:
;;   - Syntax highlighting (font-lock) via tree-sitter
;;   - Imenu support for definitions
;;
;; Requirements:
;;   - Emacs 30 or later
;;   - tree-sitter MoonBit grammar installed:
;;       M-x treesit-install-language-grammar RET moonbit RET
;;
;;     Or manually configure `treesit-language-source-alist':
;;       (add-to-list 'treesit-language-source-alist
;;                    '(moonbit "https://github.com/moonbitlang/tree-sitter-moonbit"))
;;
;; Usage:
;;   (require 'moonbit-mode)

;;; Code:

(require 'treesit)

;;; Syntax table

(defvar moonbit-mode--syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?_  "_"       table)  ; identifier constituent
    (modify-syntax-entry ?/  ". 124b"  table)  ; // and /* */ comments
    (modify-syntax-entry ?*  ". 23"    table)
    (modify-syntax-entry ?\n "> b"     table)
    (modify-syntax-entry ?\\ "\\"      table)
    (modify-syntax-entry ?\" "\""      table)  ; string delimiter
    (modify-syntax-entry ?\' "\""      table)  ; char literal delimiter
    (modify-syntax-entry ?`  "\""      table)
    table)
  "Syntax table for `moonbit-mode'.")

;;; Font-lock

(defvar moonbit-mode--keywords-type
  '("struct" "enum" "type" "trait" "typealias" "traitalias" "suberror")
  "MoonBit type definition keywords.")

(defvar moonbit-mode--keywords-fn
  '("fn" "test" "impl" "fnalias")
  "MoonBit function/impl keywords.")

(defvar moonbit-mode--keywords-modifier
  '("pub" "priv" "readonly" "all" "open" "extern")
  "MoonBit visibility/modifier keywords.")

(defvar moonbit-mode--keywords-control
  '("if" "else" "match" "while" "loop" "for" "in" "break" "continue"
    "return" "as" "is" "guard" "with" "let" "letrec" "and" "const"
    "derive" "async" "defer" "package" "import" "using"
    "try" "catch" "raise" "noraise" "nobreak" "longest" "lexmatch")
  "MoonBit control flow and binding keywords.")

(defvar moonbit-mode--builtin-types
  '("Unit" "Bool" "Byte" "Int16" "UInt16" "Int" "UInt" "Int64" "UInt64"
    "Float" "Double" "FixedArray" "Array" "Bytes" "String" "Error" "Self")
  "MoonBit built-in types.")

(defvar moonbit-mode--builtin-traits
  '("Eq" "Compare" "Hash" "Show" "Default" "ToJson" "FromJson")
  "MoonBit built-in traits.")

(defvar moonbit-mode--operators
  '("+" "-" "*" "/" "%"
    "<<" ">>" "|" "&" "^"
    "=" "+=" "-=" "*=" "/=" "%="
    "<" ">" ">=" "<=" "==" "!="
    "&&" "||"
    "|>"
    "=>" "->"
    "!" "!!" "?"
    "..<" "..=" "..<=" "..>" "..>=")
  "MoonBit operators.")

(defun moonbit-mode--font-lock-settings ()
  "Return tree-sitter font-lock settings for MoonBit."
  (treesit-font-lock-rules

   ;; ── Level 1: comment, definition ────────────────────────────────

   :language 'moonbit
   :feature 'comment
   '([(comment) (block_comment)] @font-lock-comment-face)

   :language 'moonbit
   :feature 'definition
   '(;; Function definitions
     (function_definition
      (function_identifier (lowercase_identifier) @font-lock-function-name-face))
     ;; Method definitions: Type::method
     (function_definition
      (function_identifier
       (type_name) (_)
       (lowercase_identifier) @font-lock-function-name-face))
     ;; Impl method definitions
     (impl_definition
      (function_identifier (lowercase_identifier) @font-lock-function-name-face))
     ;; Trait method declarations (in trait bodies, no fn keyword)
     (trait_method_declaration
      (function_identifier (lowercase_identifier) @font-lock-function-name-face))
     ;; Test definitions
     (test_definition (string_literal) @font-lock-function-name-face)
     ;; Type/struct/enum/trait definitions
     (struct_definition      (identifier) @font-lock-type-face)
     (tuple_struct_definition (identifier) @font-lock-type-face)
     (enum_definition        (identifier) @font-lock-type-face)
     (trait_definition       (identifier) @font-lock-type-face)
     (type_definition        (identifier) @font-lock-type-face)
     (error_type_definition  (identifier) @font-lock-type-face)
     (type_alias_definition  (type_alias_targets  (identifier) @font-lock-type-face))
     (trait_alias_definition (trait_alias_targets (identifier) @font-lock-type-face))
     ;; Const definitions
     (const_definition (uppercase_identifier) @font-lock-constant-face))

   ;; ── Level 2: keyword, string ────────────────────────────────────

   :language 'moonbit
   :feature 'keyword
   `([,@moonbit-mode--keywords-type]     @font-lock-keyword-face
     [,@moonbit-mode--keywords-fn]       @font-lock-keyword-face
     [,@moonbit-mode--keywords-modifier] @font-lock-keyword-face
     [,@moonbit-mode--keywords-control]  @font-lock-keyword-face
     [(mutability)]                          @font-lock-keyword-face
     ;; Identifiers used as keywords (defer, recur, etc.)
     ((lowercase_identifier) @font-lock-keyword-face
      (:match "\\`\\(?:import\\|using\\|defer\\|lexmatch\\|recur\\)\\'"
              @font-lock-keyword-face)))

   :language 'moonbit
   :feature 'string
   '([(string_literal)
      (multiline_string_literal)
      (string_interpolation)
      (bytes_literal)
      (regex_literal)]
     @font-lock-string-face)

   :language 'moonbit
   :feature 'string
   :override t
   '((escape_sequence) @font-lock-escape-face)

   ;; ── Level 3: type, constant, number, attribute, variable ────────

   :language 'moonbit
   :feature 'type
   '(;; General type identifiers
     (type_identifier) @font-lock-type-face
     (qualified_type_identifier) @font-lock-type-face)

   ;; Built-in types override: must be a separate block with :override t so
   ;; that builtin face wins even when a parent (e.g. type_identifier spanning
   ;; "T : Show") already claimed the region.
   :language 'moonbit
   :feature 'type
   :override t
   `(((type_identifier) @font-lock-builtin-face
      (:match ,(rx-to-string
                `(seq bol (or ,@moonbit-mode--builtin-types
                              ,@moonbit-mode--builtin-traits)
                      eol))
              @font-lock-builtin-face))
     ((qualified_type_identifier) @font-lock-builtin-face
      (:match ,(rx-to-string
                `(seq bol (or ,@moonbit-mode--builtin-types
                              ,@moonbit-mode--builtin-traits)
                      eol))
              @font-lock-builtin-face)))

   :language 'moonbit
   :feature 'constant
   '(;; Boolean literals
     (boolean_literal) @font-lock-constant-face
     ;; Enum constructors
     (enum_constructor) @font-lock-type-face
     ;; Constructor expressions (UpperCase)
     (constructor_expression (uppercase_identifier) @font-lock-type-face)
     (constructor_expression (dot_uppercase_identifier) @font-lock-type-face)
     ;; SCREAMING_SNAKE_CASE identifiers as constants
     ((constructor_expression (uppercase_identifier) @font-lock-constant-face)
      (:match "\\`[A-Z][A-Z_0-9]+\\'" @font-lock-constant-face)))

   :language 'moonbit
   :feature 'number
   '([(integer_literal) (float_literal) (double_literal)] @font-lock-number-face
     (char_literal) @font-lock-string-face)

   :language 'moonbit
   :feature 'attribute
   :override 'keep
   '((attribute) @font-lock-preprocessor-face)

   :language 'moonbit
   :feature 'variable
   '(;; Variable bindings
     (value_definition       (lowercase_identifier) @font-lock-variable-name-face)
     (let_expression         (lowercase_identifier) @font-lock-variable-name-face)
     (let_mut_expression     (lowercase_identifier) @font-lock-variable-name-face)
     (for_in_expression "for" (lowercase_identifier) @font-lock-variable-name-face "in")
     (for_binder             (lowercase_identifier) @font-lock-variable-name-face)
     ;; Parameters
     (positional_parameter   (lowercase_identifier) @font-lock-variable-name-face)
     (labelled_parameter
      (label (lowercase_identifier) @font-lock-variable-name-face))
     (optional_parameter
      (optional_label (lowercase_identifier) @font-lock-variable-name-face))
     (optional_parameter_with_default
      (label (lowercase_identifier) @font-lock-variable-name-face))
     ;; Struct fields (declarations)
     (struct_field_declaration (lowercase_identifier) @font-lock-property-name-face)
     ;; Field access
     (access_expression
      (accessor (dot_identifier) @font-lock-property-use-face))
     ;; Package identifiers
     (package_identifier) @font-lock-constant-face)

   ;; ── Level 4: function, operator, bracket, delimiter ─────────────

   :language 'moonbit
   :feature 'function
   '(;; Function calls
     (apply_expression
      (qualified_identifier (lowercase_identifier) @font-lock-function-call-face))
     (apply_expression
      (qualified_identifier (dot_lowercase_identifier) @font-lock-function-call-face))
     ;; Method calls
     (method_expression     (lowercase_identifier) @font-lock-function-call-face)
     (dot_apply_expression  (dot_identifier) @font-lock-function-call-face))

   :language 'moonbit
   :feature 'operator
   `([,@moonbit-mode--operators] @font-lock-operator-face)

   :language 'moonbit
   :feature 'bracket
   '((["(" ")" "[" "]" "{" "}"]) @font-lock-bracket-face)

   :language 'moonbit
   :feature 'delimiter
   '((["," ";" ":" "::" "." ".."]) @font-lock-delimiter-face)))

;;; Imenu

(defvar moonbit-mode--imenu-settings
  '(("Function" "\\`function_definition\\'" nil nil)
    ("Struct"   "\\`struct_definition\\'"   nil nil)
    ("Enum"     "\\`enum_definition\\'"     nil nil)
    ("Trait"    "\\`trait_definition\\'"    nil nil)
    ("Type"     "\\`type_definition\\'"     nil nil)
    ("Error"    "\\`error_type_definition\\'" nil nil)
    ("Impl"     "\\`impl_definition\\'"     nil nil)
    ("Const"    "\\`const_definition\\'"    nil nil)
    ("Test"     "\\`test_definition\\'"     nil nil))
  "Imenu settings for `moonbit-mode'.")

(defun moonbit--treesit-node-child-by-type (node type)
  "Return the first named child of NODE with node type TYPE, or nil."
  (catch 'found
    (dolist (child (treesit-node-children node t))
      (when (string= (treesit-node-type child) type)
        (throw 'found child)))))

(defun moonbit--treesit-defun-name (node)
  "Return the defun name of NODE for imenu and which-func.
Includes type parameters when present (e.g. \"foo[T, U]\").
Returns nil if NODE is not a recognized defun node."
  (pcase (treesit-node-type node)
    ;; Function definitions: fn [T] name(...)  or  fn Type::name(...)
    ("function_definition"
     (let* ((fn-id (moonbit--treesit-node-child-by-type node "function_identifier"))
            (tp    (moonbit--treesit-node-child-by-type node "type_parameters")))
       (when fn-id
         (concat (treesit-node-text fn-id)
                 (if tp (treesit-node-text tp) "")))))
    ;; Impl definitions: impl [T] Trait for Type with method(...)
    ;; Display as "Trait for Type::method"
    ("impl_definition"
     (let* ((children (treesit-node-children node t))
            (fn-id    (moonbit--treesit-node-child-by-type node "function_identifier"))
            (trait-n  (moonbit--treesit-node-child-by-type node "type_name"))
            (for-type (when (and trait-n fn-id)
                        (let ((trait-end (treesit-node-end trait-n))
                              (fn-start  (treesit-node-start fn-id)))
                          (catch 'found
                            (dolist (child children)
                              (let ((start (treesit-node-start child)))
                                (when (and (> start trait-end)
                                           (< start fn-start))
                                  (throw 'found child)))))))))
       (when fn-id
         (concat (if trait-n  (concat (treesit-node-text trait-n) " for ") "")
                 (if for-type (concat (treesit-node-text for-type) "::") "")
                 (treesit-node-text fn-id)))))
    ;; Type-like definitions: Name [T]
    ((or "struct_definition" "tuple_struct_definition"
         "enum_definition"   "trait_definition"
         "type_definition"   "error_type_definition")
     (let* ((id (moonbit--treesit-node-child-by-type node "identifier"))
            (tp (moonbit--treesit-node-child-by-type node "type_parameters")))
       (when id
         (concat (treesit-node-text id)
                 (if tp (treesit-node-text tp) "")))))
    ;; Constants
    ("const_definition"
     (let ((id (moonbit--treesit-node-child-by-type node "uppercase_identifier")))
       (when id (treesit-node-text id))))
    ;; Tests: named or anonymous
    ("test_definition"
     (let ((sl (moonbit--treesit-node-child-by-type node "string_literal")))
       (if sl (treesit-node-text sl) "<anonymous test>")))
    (_ nil)))

;;; Flymake

(defcustom moonbit-flymake-command '("moon" "check" "--output-json")
  "Command used by the `moonbit-flymake' backend.
A list of strings to invoke moon check with JSON output."
  :type '(repeat string)
  :group 'moonbit)

(defvar-local moonbit-flymake--proc nil
  "Internal variable for `moonbit-flymake'.")

(defun moonbit-flymake--project-root ()
  "Return the MoonBit project root containing moon.mod.json, or nil."
  (locate-dominating-file (or buffer-file-name default-directory)
                          "moon.mod.json"))

(defun moonbit-flymake--parse-loc (loc)
  "Parse LOC string \"SL:SC-EL:EC\" into (sl sc el ec), all as integers."
  (when (string-match
         "\\([0-9]+\\):\\([0-9]+\\)-\\([0-9]+\\):\\([0-9]+\\)"
         loc)
    (list (string-to-number (match-string 1 loc))
          (string-to-number (match-string 2 loc))
          (string-to-number (match-string 3 loc))
          (string-to-number (match-string 4 loc)))))

(defun moonbit-flymake--make-diagnostics (source)
  "Parse moon check JSON output in current buffer for source buffer SOURCE.
Return a list of Flymake diagnostic objects."
  (let ((file (buffer-file-name source))
        diags)
    (goto-char (point-min))
    (while (not (eobp))
      (let ((line (buffer-substring-no-properties
                   (point) (line-end-position))))
        (when (string-prefix-p "{" line)
          (condition-case nil
              (let* ((obj   (json-parse-string line))
                     (mtype (gethash "$message_type" obj))
                     (level (gethash "level" obj))
                     (path  (gethash "path" obj))
                     (loc   (gethash "loc" obj))
                     (msg   (gethash "message" obj)))
                (when (and (equal mtype "diagnostic")
                           (stringp path)
                           (not (string-empty-p path))
                           (equal path file))
                  (let* ((parsed (moonbit-flymake--parse-loc loc))
                         (type   (cond ((equal level "error")   :error)
                                       ((equal level "warning") :warning)
                                       (t                       :note)))
                         (region (when parsed
                                   (flymake-diag-region
                                    source
                                    (car parsed)
                                    (cadr parsed)))))
                    (push (flymake-make-diagnostic
                           source
                           (if region (car region) (point-min))
                           (if region (cdr region) (point-min))
                           type
                           msg)
                          diags))))
            (error nil))))
      (forward-line 1))
    (nreverse diags)))

(defun moonbit-flymake (report-fn &rest _args)
  "Flymake backend for MoonBit using `moon check --output-json'.
REPORT-FN is Flymake's callback."
  (when (process-live-p moonbit-flymake--proc)
    (kill-process moonbit-flymake--proc))
  (let ((source (current-buffer))
        (root   (moonbit-flymake--project-root)))
    (if (not root)
        (funcall report-fn :panic
                 :explanation "No moon.mod.json found in parent directories")
      (let ((out-buf (generate-new-buffer " *moonbit-flymake*")))
        (setq moonbit-flymake--proc
              (let ((default-directory root))
                (make-process
               :name "moonbit-flymake"
               :buffer out-buf
               :command moonbit-flymake-command
               :noquery t
               :connection-type 'pipe
               :sentinel
               (lambda (p _ev)
                 (unwind-protect
                     (when (eq 'exit (process-status p))
                       (when (with-current-buffer source
                               (eq p moonbit-flymake--proc))
                         (with-current-buffer out-buf
                           (funcall report-fn
                                    (moonbit-flymake--make-diagnostics source)))))
                   (unless (process-live-p p)
                     (kill-buffer out-buf)))))))))))

;;; Major mode

;;;###autoload
(define-derived-mode moonbit-mode prog-mode "moonbit"
  "Major mode for editing MoonBit source files (.mbt).

Uses Emacs's built-in tree-sitter library for syntax highlighting
and imenu.  Requires Emacs 30+ and the tree-sitter MoonBit grammar.

To install the grammar, add the following to your init file and run
`M-x treesit-install-language-grammar RET moonbit RET':

  (add-to-list \\='treesit-language-source-alist
               \\='(moonbit \"https://github.com/moonbitlang/tree-sitter-moonbit\"))

\\{moonbit-mode-map}"
  :group 'moonbit
  :syntax-table moonbit-mode--syntax-table

  ;; Comment style
  (setq-local comment-start "// ")
  (setq-local comment-end "")
  (setq-local comment-start-skip (rx (or (seq "/" (+ "/"))
                                         (seq "/" (+ "*")))
                                     (* (syntax whitespace))))

  (if (not (treesit-ready-p 'moonbit))
      (message "moonbit-mode: tree-sitter MoonBit grammar not available.\n\
Add (moonbit \"https://github.com/moonbitlang/tree-sitter-moonbit\") to\n\
`treesit-language-source-alist' and run M-x treesit-install-language-grammar.")
    (treesit-parser-create 'moonbit)

    ;; Font-lock
    (setq-local treesit-font-lock-settings
                (moonbit-mode--font-lock-settings))
    (setq-local treesit-font-lock-feature-list
                '((comment definition)
                  (keyword string)
                  (type constant number attribute variable)
                  (function operator bracket delimiter)))

    ;; Imenu
    (setq-local treesit-defun-name-function #'moonbit--treesit-defun-name)
    (setq-local treesit-simple-imenu-settings
                moonbit-mode--imenu-settings)

    (treesit-major-mode-setup))

  ;; Flymake
  (add-hook 'flymake-diagnostic-functions #'moonbit-flymake nil t))

;; (
;; (setq flymake-show-diagnostics-at-end-of-line t)



;;;###autoload
(add-to-list 'auto-mode-alist '("\\.mbt\\'"  . moonbit-mode))
;;;###autoload
(add-to-list 'auto-mode-alist '("\\.mbti\\'" . moonbit-mode))
;;;###autoload
(add-to-list 'auto-mode-alist '("\\.mbtx\\'" . moonbit-mode))
;;;###autoload
(add-to-list 'auto-mode-alist '("/moon\\.pkg\\'" . moonbit-mode))

(provide 'moonbit-mode)

;;; moonbit-mode.el ends here
