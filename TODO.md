# TODO: moonbit-mode.el

spec.md をもとにした実装タスク一覧。

## 現在の実装対象

### [ ] moonbit-mode.el の作成

#### Font-lock（.mbt）

- [ ] comment feature: `(comment)` `(block_comment)` → `font-lock-comment-face`
- [ ] definition feature:
  - `function_definition` 名前 → `font-lock-function-name-face`
  - `struct_definition` / `enum_definition` / `trait_definition` / `type_definition` / `error_type_definition` 名前 → `font-lock-type-face`
  - `const_definition` 名前 → `font-lock-constant-face`
  - `test_definition` 名前 → `font-lock-function-name-face`
  - `impl_definition` の関数名 → `font-lock-function-name-face`
- [ ] keyword feature:
  - 型定義キーワード: `struct` `enum` `type` `trait` `typealias` `traitalias` `suberror`
  - 宣言キーワード: `fn` `test` `impl` `fnalias`
  - バインドキーワード: `let` `letrec` `and` `const` `with`
  - 制御フロー: `if` `else` `match` `while` `loop` `for` `in` `break` `continue`
  - 例外: `try` `catch` `raise` `noraise`
  - その他: `return` `as` `is` `guard` `defer` `async` `derive` `package` `import` `using`
  - 修飾子: `pub` `priv` `readonly` `all` `open` `extern` `(mutability)` → `font-lock-keyword-face`
- [ ] string feature:
  - `(string_literal)` `(multiline_string_literal)` `(string_interpolation)` `(bytes_literal)` → `font-lock-string-face`
  - `(escape_sequence)` → `font-lock-escape-face`
- [ ] type feature:
  - `(type_identifier)` `(qualified_type_identifier)` → `font-lock-type-face`
  - builtin types (Unit / Bool / Int / UInt / Int64 / UInt64 / Float / Double / String / Array / FixedArray / Bytes / Byte / Error / Self 等) → `font-lock-builtin-face`
- [ ] constant feature:
  - `(boolean_literal)` → `font-lock-constant-face`
  - `(enum_constructor)` → `font-lock-type-face`
- [ ] number feature:
  - `(integer_literal)` `(float_literal)` → `font-lock-number-face`
  - `(char_literal)` → `font-lock-string-face`
- [ ] attribute feature:
  - `(attribute)` → `font-lock-preprocessor-face`
- [ ] variable feature:
  - `let_expression` / `let_mut_expression` / `value_definition` の変数名 → `font-lock-variable-name-face`
  - 各種パラメータ（positional / labelled / optional）→ `font-lock-variable-name-face`
  - `struct_field_declaration` → `font-lock-property-name-face`
  - `access_expression` のフィールド → `font-lock-property-use-face`
- [ ] function feature:
  - 関数呼び出し (apply_expression) → `font-lock-function-call-face`
  - メソッド呼び出し (method_expression, dot_apply_expression) → `font-lock-function-call-face`
- [ ] operator feature: 各種演算子 → `font-lock-operator-face`
- [ ] bracket feature: `( ) [ ] { }` → `font-lock-bracket-face`
- [ ] delimiter feature: `, ; : :: . ..` → `font-lock-delimiter-face`

#### Imenu

- [ ] `treesit-simple-imenu-settings` で以下の定義一覧を提供:
  - Function: `function_definition`
  - Struct: `struct_definition`
  - Enum: `enum_definition`
  - Trait: `trait_definition`
  - Type: `type_definition`
  - Impl: `impl_definition`
  - Const: `const_definition`
  - Test: `test_definition`

#### モードの基本設定

- [ ] `define-derived-mode moonbit-ts-mode prog-mode`
- [ ] コメント設定 (`comment-start` = `"// "`)
- [ ] シンタックステーブルの定義
- [ ] `auto-mode-alist` への `.mbt` 登録
- [ ] `treesit-ready-p` チェック付き初期化

---

## 次回実装（将来）

### [ ] .mbti サポート（インターフェースファイル）

- `.mbti` は `.mbt` と同じ `moonbit` grammar を使用（別 grammar 不要）
- body なし宣言（`fn[T] abort(String) -> T`、`impl Show for Int` 等）に対応済み
- `auto-mode-alist` への `.mbti` 登録のみで動作するはず
  ```elisp
  (add-to-list 'auto-mode-alist '("\\.mbti\\'" . moonbit-ts-mode))
  ```

### [ ] moon.pkg サポート（パッケージマニフェスト）

- `moon.pkg` も同じ `moonbit` grammar を使用（assignment / apply statement 形式）
- `auto-mode-alist` へのファイル名ベース登録が必要（拡張子ではなくファイル名）
  ```elisp
  (add-to-list 'auto-mode-alist '("/moon\\.pkg\\'" . moonbit-ts-mode))
  ```

### [ ] インデント

- `treesit-simple-indent-rules` の実装
- ブロック / match / if-else / 引数リスト等

### [ ] Navigation

- `treesit-defun-type-regexp` による defun 移動
- `treesit-thing-settings` による sexp / sentence 移動

### [ ] その他

- Electric characters
- Which-function モード対応
- コードフォールディング（外部パッケージ連携）
