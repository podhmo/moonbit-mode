# tree-sitter を使った moonbit-mode で実装できる機能

`typescript-ts-mode.el`（`/Applications/Emacs.app/Contents/Resources/lisp/progmodes/typescript-ts-mode.el.gz`）および `refs/moonbitlang/tree-sitter-moonbit/queries/highlights.scm` を参照して整理した、tree-sitter（Emacs 29+ 組み込み `treesit` ライブラリ）で実装できる機能の全一覧。

参考実装:
- `refs/mini-python-mode/mini-python-ts-mode.el`（最小テンプレート）
- `typescript-ts-mode.el`（フル実装の参考）

---

## 1. Font-lock（構文ハイライト）

### 設定方法

```elisp
(setq-local treesit-font-lock-settings
            (treesit-font-lock-rules ...))
(setq-local treesit-font-lock-feature-list
            '((comment definition)
              (keyword string)
              (type constant number attribute)
              (operator function bracket delimiter variable)))
```

`treesit-font-lock-feature-list` は 4 段階のレベルでグループ化する。`treesit-font-lock-level`（デフォルト 3）でどのレベルまで有効にするかを制御する。ユーザーが `M-x customize-variable treesit-font-lock-level` で調整できる。

### feature 一覧

#### レベル 1（最優先）

| feature | 対象ノード（tree-sitter クエリ） | face |
|---------|-------------------------------|------|
| `comment` | `(comment)` `(block_comment)` | `font-lock-comment-face` |
| `definition` | `(function_definition (function_identifier ...) @name)` | `font-lock-function-name-face` |
| | `(struct_definition (identifier) @name)` | `font-lock-type-face` |
| | `(enum_definition (identifier) @name)` | `font-lock-type-face` |
| | `(trait_definition (identifier) @name)` | `font-lock-type-face` |
| | `(type_definition (identifier) @name)` | `font-lock-type-face` |
| | `(error_type_definition (identifier) @name)` | `font-lock-type-face` |
| | `(const_definition (uppercase_identifier) @name)` | `font-lock-constant-face` |
| | `(test_definition (string_literal) @name)` | `font-lock-function-name-face` |

#### レベル 2

| feature | 対象ノード | face |
|---------|-----------|------|
| `keyword` | `"fn"` `"test"` `"impl"` `"fnalias"` | `font-lock-keyword-face` |
| | `"let"` `"letrec"` `"and"` `"const"` `"with"` `"as"` `"is"` `"guard"` | `font-lock-keyword-face` |
| | `"if"` `"else"` `"match"` | `font-lock-keyword-face` |
| | `"while"` `"loop"` `"for"` `"break"` `"continue"` `"in"` `"nobreak"` | `font-lock-keyword-face` |
| | `"return"` | `font-lock-keyword-face` |
| | `"try"` `"catch"` `"raise"` `"noraise"` | `font-lock-keyword-face` |
| | `"struct"` `"enum"` `"type"` `"trait"` `"typealias"` `"traitalias"` `"suberror"` | `font-lock-keyword-face` |
| | `"pub"` `"priv"` `"readonly"` `"all"` `"open"` `"extern"` `(mutability)` | `font-lock-keyword-face` |
| | `"package"` `"import"` `"using"` | `font-lock-keyword-face` |
| | `"async"` `"derive"` `"defer"` `"recur"` `"lexmatch"` `"longest"` | `font-lock-keyword-face` |
| `string` | `(string_literal)` `(multiline_string_literal)` `(string_interpolation)` | `font-lock-string-face` |
| | `(bytes_literal)` `(regex_literal)` | `font-lock-string-face` |
| | `(escape_sequence)` | `font-lock-escape-face` |
| | `(interpolator "\\{" @p "}" @p)` | `font-lock-misc-punctuation-face` |

#### レベル 3

| feature | 対象ノード | face |
|---------|-----------|------|
| `type` | `(type_identifier)` `(qualified_type_identifier)` | `font-lock-type-face` |
| | builtin types: `"Unit"` `"Bool"` `"Int"` `"UInt"` `"Int64"` `"UInt64"` `"Float"` `"Double"` `"String"` `"Array"` `"FixedArray"` `"Bytes"` `"Byte"` `"Int16"` `"UInt16"` `"Error"` `"Self"` | `font-lock-builtin-face` |
| | builtin traits: `"Eq"` `"Compare"` `"Hash"` `"Show"` `"Default"` `"ToJson"` `"FromJson"` | `font-lock-builtin-face` |
| `constant` | `(boolean_literal)` | `font-lock-constant-face` |
| | `(enum_constructor)` | `font-lock-type-face` |
| | `(constructor_expression (uppercase_identifier))` で全大文字のもの | `font-lock-constant-face` |
| `number` | `(integer_literal)` | `font-lock-number-face` |
| | `(float_literal)` | `font-lock-number-face` |
| | `(char_literal)` | `font-lock-string-face` |
| `attribute` | `(attribute)` | `font-lock-preprocessor-face` |
| | `(derive_directive)` | `font-lock-preprocessor-face` |
| `variable` | `(value_definition (lowercase_identifier))` `(let_expression (lowercase_identifier))` | `font-lock-variable-name-face` |
| | `(positional_parameter (lowercase_identifier))` | `font-lock-variable-name-face` |
| | `(labelled_parameter (label (lowercase_identifier)))` | `font-lock-variable-name-face` |
| | `(struct_field_declaration (lowercase_identifier))` | `font-lock-property-name-face` |
| | `(access_expression (accessor (dot_identifier)))` | `font-lock-property-use-face` |

#### レベル 4

| feature | 対象ノード | face |
|---------|-----------|------|
| `function` | `(apply_expression (qualified_identifier (lowercase_identifier)))` | `font-lock-function-call-face` |
| | `(method_expression (lowercase_identifier))` | `font-lock-function-call-face` |
| | `(dot_apply_expression (dot_identifier))` | `font-lock-function-call-face` |
| `operator` | `"+"` `"-"` `"*"` `"/"` `"%"` `"<<"` `">>"` `"\|"` `"&"` `"^"` | `font-lock-operator-face` |
| | `"="` `"+="` `"-="` `"*="` `"/="` `"%="` | `font-lock-operator-face` |
| | `"<"` `">"` `">="` `"<="` `"=="` `"!="` `"&&"` `"\|\|"` | `font-lock-operator-face` |
| | `"\|>"` `"=>"` `"->"` `"!"` `"!!"` `"?"` | `font-lock-operator-face` |
| | range: `"..<"` `"..="` `"..<="` `"..>"` `"..>="` | `font-lock-operator-face` |
| `bracket` | `"("` `")"` `"["` `"]"` `"{"` `"}"` | `font-lock-bracket-face` |
| `delimiter` | `","` `";"` `":"` `"::"` `"."` `".."` | `font-lock-delimiter-face` |

---

## 2. Indentation（インデント）

### 設定方法

```elisp
(setq-local treesit-simple-indent-rules
            `((moonbit
               ((parent-is "structure") column-0 0)
               ((node-is "}") standalone-parent 0)
               ((node-is ")") parent-bol 0)
               ((node-is "]") parent-bol 0)
               ((parent-is "block_expression") standalone-parent ,offset)
               ...)))
```

`treesit-simple-indent-rules` は `(MATCHER ANCHOR OFFSET)` のリスト。`typescript-ts-mode` の実装がフルリファレンスとなる。

### 主なルール候補

| 条件 (`MATCHER`) | アンカー (`ANCHOR`) | オフセット | 説明 |
|-----------------|-------------------|-----------|------|
| `(parent-is "structure")` | `column-0` | `0` | トップレベルは列 0 |
| `(node-is "}")` | `standalone-parent` | `0` | `}` はブロック開始に揃える |
| `(node-is ")")` | `parent-bol` | `0` | `)` は行頭に揃える |
| `(node-is "]")` | `parent-bol` | `0` | `]` は行頭に揃える |
| `(parent-is "block_expression")` | `standalone-parent` | `+N` | ブロック内をインデント |
| `(parent-is "match_expression")` | `parent-bol` | `+N` | match 本体 |
| `(parent-is "case_clause")` | `parent-bol` | `+N` | case 本体 |
| `(parent-is "matrix_case_clause")` | `parent-bol` | `+N` | matrix case 本体 |
| `(parent-is "if_expression")` | `parent-bol` | `+N` | if 本体 |
| `(parent-is "else_clause")` | `parent-bol` | `+N` | else 本体 |
| `(parent-is "while_expression")` | `parent-bol` | `+N` | while 本体 |
| `(parent-is "for_expression")` | `parent-bol` | `+N` | for 本体 |
| `(parent-is "loop_expression")` | `parent-bol` | `+N` | loop 本体 |
| `(parent-is "parameters")` | `parent-bol` | `+N` | 引数リスト |
| `(parent-is "arguments")` | `parent-bol` | `+N` | 呼び出し引数 |
| `(parent-is "type_parameters")` | `parent-bol` | `+N` | 型引数リスト |
| `(parent-is "type_arguments")` | `parent-bol` | `+N` | 型適用引数 |
| `(parent-is "struct_definition")` | `parent-bol` | `+N` | struct フィールド |
| `(parent-is "enum_definition")` | `parent-bol` | `+N` | enum コンストラクタ |
| `(parent-is "impl_definition")` | `parent-bol` | `+N` | impl メソッド |
| `(parent-is "trait_definition")` | `parent-bol` | `+N` | trait メソッド宣言 |
| `(parent-is "function_definition")` | `parent-bol` | `+N` | 関数本体（ `{` の後） |
| `(parent-is "try_catch_expression")` | `parent-bol` | `+N` | try 本体 |
| コメント行継続 | `prev-adaptive-prefix` | `0` | `//` コメントの継続行 |
| `no-node` | `parent-bol` | `0` | ノードがない行（フォールバック） |

---

## 3. Imenu（定義ジャンプ）

### 設定方法

```elisp
(setq-local treesit-simple-imenu-settings
            '(("Function" "\\`function_definition\\'" nil nil)
              ("Struct"   "\\`struct_definition\\'"   nil nil)
              ("Enum"     "\\`enum_definition\\'"     nil nil)
              ("Trait"    "\\`trait_definition\\'"    nil nil)
              ("Type"     "\\`type_definition\\'"     nil nil)
              ("Error"    "\\`error_type_definition\\'" nil nil)
              ("Impl"     "\\`impl_definition\\'"     nil nil)
              ("Const"    "\\`const_definition\\'"    nil nil)
              ("Test"     "\\`test_definition\\'"     nil nil)))
```

`M-x imenu`（または `M-g i`）でバッファ内の定義一覧にジャンプできる。`consult-imenu` 等のパッケージとも連携する。

---

## 4. Navigation（移動）

### defun 移動（`C-M-a` / `C-M-e`、`beginning-of-defun` / `end-of-defun`）

```elisp
(setq-local treesit-defun-type-regexp
            (rx bos (or "function_definition"
                        "struct_definition"
                        "enum_definition"
                        "trait_definition"
                        "type_definition"
                        "error_type_definition"
                        "impl_definition"
                        "const_definition"
                        "test_definition")
                eos))
```

オプションで述語関数 `treesit-defun-type-regexp` をコンスペアで指定し、特定のノードのみ defun として扱うフィルタリングもできる（`typescript-ts-mode` の `lexical_declaration` 判定が参考例）。

### defun 名の取得（which-function-mode 用）

```elisp
(setq-local treesit-defun-name-function
            (lambda (node)
              (pcase (treesit-node-type node)
                ("function_definition"
                 (treesit-node-text
                  (treesit-node-child-by-field-name node "name") t))
                ((or "struct_definition" "enum_definition"
                     "trait_definition" "type_definition")
                 (treesit-node-text
                  (treesit-node-child node 0 'named) t))
                (_ nil))))
```

### sexp / sentence 移動（`C-M-f` / `C-M-b`、`M-a` / `M-e`）

```elisp
(setq-local treesit-thing-settings
            `((moonbit
               (sexp ,(regexp-opt
                       '("expression" "pattern" "array" "function"
                         "string" "escape" "number" "identifier"
                         "boolean" "tuple" "struct" "arguments"
                         "block" "lambda")))
               (sentence ,(regexp-opt
                           '("function_definition"
                             "struct_definition"
                             "enum_definition"
                             "const_definition"
                             "value_definition"
                             "let_expression"
                             "if_expression"
                             "match_expression"
                             "while_expression"
                             "for_expression"
                             "loop_expression"
                             "return_expression"
                             "import_declaration"
                             "package_declaration")))
               (text ,(regexp-opt '("comment" "block_comment"
                                    "string_literal"
                                    "multiline_string_literal"))))))
```

`treesit-thing-settings` は Emacs 30 以降で利用可能。`forward-sexp` / `backward-sexp` / `kill-sexp` 等の標準コマンドも tree-sitter ベースで動作するようになる。

---

## 5. コメント設定

tree-sitter とは独立しているが、major mode として必須の設定。

```elisp
;; MoonBit のコメント形式
(setq-local comment-start "// ")
(setq-local comment-end "")
(setq-local comment-start-skip (rx (or (seq "/" (+ "/"))
                                       (seq "/" (+ "*")))
                                   (* (syntax whitespace))))
(setq-local comment-end-skip
            (rx (* (syntax whitespace))
                (group (or (syntax comment-end)
                           (seq (+ "*") "/")))))
```

`c-ts-common-comment-setup`（`c-ts-common.el`）を利用すれば C スタイルコメントの fill/indent もまとめて設定できる。

---

## 6. Syntax Table（シンタックステーブル）

`font-lock-syntactic-keywords` より前の段階で文字の構文クラスを定義する。文字列・コメントの認識に影響する。

```elisp
(defvar moonbit-mode--syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?_  "_"       table)  ; 識別子の一部
    (modify-syntax-entry ?/  ". 124b"  table)  ; // と /* */ コメント
    (modify-syntax-entry ?*  ". 23"    table)
    (modify-syntax-entry ?\n "> b"     table)
    (modify-syntax-entry ?\\ "\\"      table)
    (modify-syntax-entry ?\" "\""      table)  ; 文字列
    (modify-syntax-entry ?\' "\""      table)  ; 文字リテラル
    table))
```

---

## 7. Electric Characters（電気的インデント）

入力時に自動的にインデントを調整する文字の設定。

```elisp
(setq-local electric-indent-chars
            (append "{}();," electric-indent-chars))
(setq-local electric-layout-rules
            '((?\{ . after) (?\} . before)))
```

---

## 8. コードフォールディング

`treesit-fold`（外部パッケージ）または `hs-minor-mode` との連携で折りたたみ可能なノード。
`refs/moonbitlang/tree-sitter-moonbit/queries/folds.scm` より:

```scheme
; folds.scm の内容
[
  (block_expression)
  (match_expression)
  (struct_definition)
  (enum_definition)
  (function_definition)
  (value_definition)
  (if_expression)
] @fold
```

`treesit-fold` を使う場合:

```elisp
(setq treesit-fold-range-alist
      '((moonbit-mode
         (block_expression   . treesit-fold-range-block)
         (match_expression   . treesit-fold-range-block)
         (function_definition . treesit-fold-range-block)
         (struct_definition  . treesit-fold-range-block)
         (enum_definition    . treesit-fold-range-block)
         (if_expression      . treesit-fold-range-block))))
```

---

## 9. Which-function（モードラインへの関数名表示）

`which-function-mode` を有効にすることで、カーソル位置の関数・型名をモードラインに表示できる。
設定は「4. Navigation」の `treesit-defun-name-function` を参照。

---

## 10. Structural Editing / Paredit 的操作

`combobulate`（外部パッケージ）や `evil-textobj-tree-sitter` と組み合わせると、tree-sitter のノード単位でのカット・コピー・置換ができる。標準の `treesit-thing-settings` 設定があれば多くの操作が自動的に機能する。

---

## 11. xref / 定義ジャンプ

`eglot`（LSP クライアント）と組み合わせることで `M-.`（定義ジャンプ）や `M-?`（参照検索）が利用できる。tree-sitter 単体では実装不可（LSP または ctags が必要）。

---

## 12. デバッグ・開発補助

実装時に有用な tree-sitter 組み込みコマンド:

| コマンド | 説明 |
|---------|------|
| `M-x treesit-inspect-mode` | カーソル位置のノード情報をエコーエリアに表示 |
| `M-x treesit-explore-mode` | tree-sitter のパースツリーを別ウィンドウに表示 |
| `M-x treesit-install-language-grammar` | tree-sitter grammar のインストール |
| `treesit-node-at` | Elisp からカーソル位置のノードを取得 |
| `treesit-query-capture` | クエリのテスト実行 |

---

## 付録A：実装優先度

| 優先度 | 機能 | Emacs 設定変数 | 実装コスト |
|--------|------|--------------|-----------|
| **高** | Font-lock（コメント・定義・キーワード・文字列・型） | `treesit-font-lock-rules` | 低 |
| **高** | コメント設定 | `comment-start` 等 | 低 |
| **高** | Imenu（関数・型定義一覧） | `treesit-simple-imenu-settings` | 低 |
| 中 | Font-lock（演算子・ブラケット・変数・属性） | `treesit-font-lock-rules` | 低 |
| 中 | defun 移動 | `treesit-defun-type-regexp` | 低 |
| 中 | Syntax Table | `make-syntax-table` | 低 |
| 中 | Electric chars | `electric-indent-chars` | 低 |
| 低 | Indentation | `treesit-simple-indent-rules` | 高 |
| 低 | sexp / sentence 移動 | `treesit-thing-settings` | 中 |
| 低 | コードフォールディング | `treesit-fold`（外部） | 中 |
| 低 | Which-function | `treesit-defun-name-function` | 低 |
| 低 | Structural Editing | `combobulate`（外部） | - |

## 付録B：主要ノード型一覧（moonbit tree-sitter grammar）

`refs/moonbitlang/tree-sitter-moonbit/queries/highlights.scm` より抜粋。

### トップレベル定義
- `function_definition`, `test_definition`, `struct_definition`, `enum_definition`
- `trait_definition`, `impl_definition`, `type_definition`, `error_type_definition`
- `const_definition`, `value_definition`
- `type_alias_definition`, `trait_alias_definition`, `function_alias_definition`
- `package_declaration`, `import_declaration`, `using_declaration`

### 式
- `if_expression`, `else_clause`
- `match_expression`, `case_clause`, `matrix_case_clause`
- `while_expression`, `loop_expression`, `for_expression`, `for_in_expression`
- `block_expression`, `let_expression`, `let_mut_expression`
- `apply_expression`, `method_expression`, `dot_apply_expression`
- `binary_expression`, `unary_expression`, `assignment_expression`
- `constructor_expression`, `struct_expression`, `array_expression`, `tuple_expression`
- `return_expression`, `break_expression`, `continue_expression`, `raise_expression`
- `try_catch_expression`, `guard_expression`, `defer_expression`
- `anonymous_lambda_expression`, `arrow_function_expression`
- `as_expression`, `is_expression`
- `range_expression`, `access_expression`

### パターン
- `any_pattern`, `tuple_pattern`, `array_pattern`
- `constructor_pattern`, `struct_pattern`, `map_pattern`
- `as_pattern`, `or_pattern`, `constraint_pattern`, `range_pattern`

### 型
- `type_identifier`, `qualified_type_identifier`
- `apply_type`, `tuple_type`, `function_type`, `option_type`
- `type_parameters`, `type_arguments`, `constraints`

### リテラル
- `string_literal`, `multiline_string_literal`, `string_interpolation`, `bytes_literal`, `regex_literal`
- `integer_literal`, `float_literal`, `boolean_literal`, `char_literal`
- `escape_sequence`

### 識別子
- `identifier`, `uppercase_identifier`, `lowercase_identifier`
- `qualified_identifier`, `qualified_type_identifier`
- `package_identifier`, `function_identifier`
- `dot_identifier`, `dot_lowercase_identifier`, `dot_uppercase_identifier`

### コメント
- `comment`（`//` 行コメント）
- `block_comment`（`/* */` ブロックコメント）

### 属性
- `attribute`（`#[...]`）, `derive_directive`（`derive(...)` 相当）
