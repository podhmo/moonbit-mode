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

`treesit-font-lock-rules` の `:override t` を指定すると、すでに別ルールで face がついているノードを上書きできる。通常は不要だが、変数に代入された関数などを関数名 face で上書きしたい場合に使う（typescript-ts-mode の `declaration` feature が参考例）。
