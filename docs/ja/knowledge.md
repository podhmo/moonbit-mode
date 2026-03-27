# 調査で得られた知見

moonbit-mode.el の実装にあたって調査で判明した事項をまとめる。

---

## tree-sitter grammar

### 言語名・ファイルタイプ

`refs/moonbitlang/tree-sitter-moonbit/tree-sitter.json` より:

- **tree-sitter 言語名**: `moonbit`（`treesit-parser-create` / `treesit-ready-p` に渡す名前）
- **対応ファイルタイプ**: `mbt`, `mbti`, `moonbit`, `moon.pkg`
- **スコープ**: `source.moonbit`
- **injection-regex**: `^(mbt|moonbit)$`

文法は単一（`grammar.js`）で、`.mbt` / `.mbti` / `moon.pkg` すべてを同一 grammar で処理する。

### 主要ファイル

| ファイル | 用途 |
|---------|------|
| `grammar.js` | 文法定義本体（約 1500 行） |
| `src/scanner.c` | 外部スキャナ（自動セミコロン挿入等） |
| `queries/highlights.scm` | シンタックスハイライト用クエリ |
| `queries/locals.scm` | スコープ・変数定義追跡 |
| `queries/tags.scm` | LSP タグ定義 |
| `queries/folds.scm` | コードフォールディング対象ノード |
| `test/corpus/mbti.txt` | .mbti フォーマットのテストコーパス |
| `test/corpus/package.txt` | moon.pkg フォーマットのテストコーパス |

---

## ファイルフォーマット別の特徴

### .mbt（ソースファイル）

通常の MoonBit ソースコード。関数本体・式・文を含む。

### .mbti（インターフェースファイル）

公開 API のシグネチャのみを宣言するファイル。同じ `moonbit` grammar を使用。

**`.mbt` との違い:**
- 関数・impl の body を省略できる（`.mbt` では必須）
- 戻り値型 `->` が ASI（自動セミコロン挿入）との曖昧性解消のため必要になる場合がある

**構文例:**
```moonbit
package "moonbitlang/core/builtin"

import {
  "moonbitlang/core/array"
}

// 関数宣言（body なし）
fn[T] abort(String) -> T

// impl 宣言（body なし）
impl Show for Int
impl[T : Show] Show for Array[T]

// let 宣言（型のみ）
pub let default_capacity : Int

// trait 宣言（body なし）
pub trait Show
pub trait MyTrait : Eq

// async 関数宣言
pub async fn fetch(String) -> String
```

**Emacs 対応:** 同じ `moonbit-mode` に `auto-mode-alist` 登録するだけで動作する。

```elisp
(add-to-list 'auto-mode-alist '("\\.mbti\\'" . moonbit-mode))
```

### moon.pkg（パッケージマニフェスト）

MoonBit パッケージの設定ファイル。同じ `moonbit` grammar を使用。
JSON ではなく MoonBit 独自の設定構文（assignment statement / apply statement 形式）。

**構文例:**
```moonbit
// assignment statement
warnings = "+unused_value-deprecated"
test-import-all = true
flags = ["js", "wasm-gc", 2]

// ネストしたマップ
links = {
  "js": {
    "exports": ["setup", "compile", "search"],
  },
}

// apply statement（関数呼び出し形式）
options(
  "is-main": true,
  formatter: {
    "ignore": [],
  },
  supported_targets: ["native"],
)

// import 宣言
import {
  "moonbitlang/core/json",
  "moonbitlang/x/path" @xpath,
}

// for 句つき import
import {
  "moonbitlang/async",
} for "test"
```

**Emacs 対応:** ファイル名ベースのマッチが必要（拡張子ではなくファイル名）。

```elisp
(add-to-list 'auto-mode-alist '("/moon\\.pkg\\'" . moonbit-mode))
```

---

## Emacs tree-sitter API メモ

### grammar インストール設定

```elisp
(add-to-list 'treesit-language-source-alist
             '(moonbit "https://github.com/moonbitlang/tree-sitter-moonbit"))
;; その後: M-x treesit-install-language-grammar RET moonbit RET
```

### デバッグ用コマンド

| コマンド | 説明 |
|---------|------|
| `M-x treesit-inspect-mode` | カーソル位置のノード型をエコーエリアに表示 |
| `M-x treesit-explore-mode` | パースツリーを別ウィンドウに表示 |
| `(treesit-node-at (point))` | 現在位置のノードを Elisp から取得 |
| `(treesit-node-type node)` | ノード型の文字列を取得 |

### `treesit-font-lock-feature-list` の構造

4 段階のレベル。`treesit-font-lock-level`（デフォルト 3）で有効レベルを制御。

```elisp
(setq-local treesit-font-lock-feature-list
            '((comment definition)        ; level 1
              (keyword string)            ; level 2
              (type constant number ...)  ; level 3
              (operator bracket ...)))    ; level 4
```

### `:override` オプション

`treesit-font-lock-rules` の `:override` は font-lock 競合時の挙動を制御する。

| 値 | 挙動 |
|----|------|
| `nil`（デフォルト） | 範囲内に 1 文字でも face があれば**全体をスキップ** |
| `t` | 常に上書き（既存 face を置き換え） |
| `'keep'` | face がない位置だけを埋める（`font-lock-fillin-text-property`） |
| `'append'` | 既存 face に追加 |
| `'prepend'` | 既存 face の前に挿入 |

#### よくある問題と対策

**親ノードが子ノードの face を妨げる**:
`string_literal` に `font-lock-string-face` が付いた後、その子の `escape_sequence` に `font-lock-escape-face` を付けたい場合、`:override nil` では子ノードの range が既に claim されているため無視される。
→ `escape_sequence` のルールを **`:override t` の別ブロック**に分離する。

**汎用ルールが特定ルールを先取りする**:
`(qualified_type_identifier) @type-face` が先に実行され、その後の builtin チェック `((qualified_type_identifier) @builtin-face (:match ...))` が上書きできない（型パラメータの `type_identifier` が `T : Show` 全体を span し `Show` 部分を先取りするケースなど）。
→ builtin チェックを **`:override t` の別ブロック**に分離して後から適用する。

**attribute 内の文字列 face が attribute face を妨げる**:
`string` feature（level 2）が `attribute` 内の文字列に face を設定した後、`attribute` feature（level 3）が `(attribute) @preprocessor-face` で全体を塗ろうとしても `:override nil` だとスキップされる。
→ attribute ルールに **`:override 'keep'`** を指定する（face がない箇所だけを塗る）。

---

## MoonBit ノード型メモ

### 数値リテラルのノード型

| 値の例 | tree-sitter ノード型 |
|--------|---------------------|
| `42`, `0xFF`, `0b1010` | `integer_literal` |
| `3.14` | `double_literal` |
| `3.14F` | `float_literal`（`F` サフィックス付き） |
| `'A'` | `char_literal` |

**注意**: `float_literal` は `F` サフィックス付きのみ。通常の小数点数は `double_literal`。

### imenu / defun-name

`treesit-defun-name-function` に設定する `moonbit--treesit-defun-name` は、ノード型ごとに適切な名前を返す。

**ノード型別の名前構築ルール:**

| ノード型 | 名前の構成 | 例 |
|---------|-----------|-----|
| `function_definition` | `function_identifier` + `type_parameters`(任意) | `option_or_default[T]`, `Environment::new` |
| `impl_definition` | `type_name for for-type::function_identifier` | `Show for Expression::to_string` |
| `struct_definition` / `enum_definition` / `trait_definition` / `type_definition` / `error_type_definition` | `identifier` + `type_parameters`(任意) | `Pair[T]`, `Expression` |
| `const_definition` | `uppercase_identifier` | `MAX_SIZE` |
| `test_definition` | `string_literal`（なければ `<anonymous test>`） | `"my test"`, `<anonymous test>` |

**実装上の注意点:**

`(treesit-node-child node 1)` のような位置ベースのアクセスは使わない。`fn[T] foo(...)` では child[1] が `type_parameters` になるため、関数名を取り逃す。代わりに `moonbit--treesit-node-child-by-type` ヘルパーでノード型名による検索を行う。

`impl_definition` の "for 型" の取得は、`type_name`（トレイト名）の終端位置と `function_identifier`（メソッド名）の開始位置の間にある named child を探すことで行う。"for 型" のノード型は文脈によって `qualified_type_identifier`, `apply_type` などさまざまであるため、型名指定ではなく位置によるフィルタリングを使う。

### trait メソッド宣言

`.mbt` の trait 本体および `.mbti` のインターフェース宣言でのメソッド宣言は `fn` キーワードを**使わない**。

```moonbit
trait Printable {
  print(Self) -> Unit   // ← fn なし、これが正しい構文
}
```

tree-sitter ノード型は `trait_method_declaration`（`function_definition` ではない）。font-lock で関数名を強調したい場合は別途ルールが必要：

```elisp
(trait_method_declaration
 (function_identifier (lowercase_identifier) @font-lock-function-name-face))
```

