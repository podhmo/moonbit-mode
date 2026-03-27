# moonbit-mode テスト方法

## 概要

`moonbit-mode` のテストは Emacs 標準の ERT（Emacs Lisp Regression Testing）フレームワークと、フォントロック専用の `ert-font-lock` ライブラリを組み合わせて実装している。

---

## 実行方法

### Makefile 経由（推奨）

```bash
make test
```

### コマンドライン直接実行

```bash
emacs --batch \
  -l moonbit-mode.el \
  -l test/test-moonbit-mode.el \
  -f ert-run-tests-batch-and-exit
```

---

## 前提条件

| 要件 | 詳細 |
|------|------|
| Emacs バージョン | 29 以上（tree-sitter 組み込み版） |
| `ert-font-lock` | Emacs 30+ は標準搭載。Emacs 29 では `M-x package-install RET ert-font-lock` |
| tree-sitter MoonBit 文法 | `~/.emacs.d/tree-sitter/` にインストール済みであること |

ローカルソースからの文法インストールは `test/test-moonbit-mode.el` が自動的に行う（`refs/moonbitlang/tree-sitter-moonbit/` を使用、ネットワーク不要）。

---

## テスト構造

### テストファイル

```
test/
└── test-moonbit-mode.el   ERT テスト定義
test/testdata/
├── font-lock.mbt          .mbt フォントロック検証ファイル（アノテーション付き）
├── font-lock.mbti         .mbti フォントロック検証ファイル（アノテーション付き）
└── moon.pkg               moon.pkg フォントロック検証ファイル（アノテーション付き）
```

### テスト種別

| テスト名 | 内容 |
|---------|------|
| `moonbit-mode-auto-mode-mbt` | `.mbt` ファイルで `moonbit-mode` が有効になることを確認 |
| `moonbit-mode-auto-mode-mbti` | `.mbti` ファイルで `moonbit-mode` が有効になることを確認 |
| `moonbit-mode-auto-mode-moon-pkg` | `moon.pkg` ファイルで `moonbit-mode` が有効になることを確認 |
| `moonbit-mode-font-lock-mbt` | `test/testdata/font-lock.mbt` のアノテーションを検証 |
| `moonbit-mode-font-lock-mbti` | `test/testdata/font-lock.mbti` のアノテーションを検証 |
| `moonbit-mode-font-lock-moon-pkg` | `test/testdata/moon.pkg` のアノテーションを検証 |

---

## `ert-font-lock` アノテーション構文

`ert-font-lock` は「検証したい face 情報をソースコードのコメントに書く」形式。テスト実行時にソースを開いてフォントロックを適用し、アノテーションが指定する位置の face を検証する。

### カーソル指定（`^`）

ソースの直後の行に `//^` を書く。`^` の数だけ文字をチェックし、その文字が指定した face を持っているか確認する。

```moonbit
let count = 42
//          ^^ font-lock-number-face
```

`//` を含む列位置が直接ソース列にマッピングされる。**`//` は 2 文字分の位置を占める**ことに注意。

#### 例: カラム位置の計算

```
fn greet(name : String) -> String
// ^^^^^ font-lock-function-name-face
```

- `//` が列 0-1 を占める
- ` ` (スペース) が列 2
- 最初の `^` が列 3 → ソース列 3 = `g` (greet の先頭)
- 5 個の `^` で列 3-7 をチェック = `greet`

### 行頭チェック（`<-`）

```moonbit
// コメント行
// <- font-lock-comment-face
```

`// <-` はその直前のソース行の **列 0** をチェックする。

### 否定アサーション（`!`）

指定した face が**付いていない**ことを確認する。

```moonbit
let x = 42
//      ^^ !font-lock-string-face
```

---

## フォントロック検証ファイルの構成

`test/testdata/font-lock.mbt` は `treesit-font-lock-level 4`（全フィーチャ有効）を前提として作成されており、level 1 から level 4 までのフィーチャを網羅的に検証する。

| Level | フィーチャ |
|-------|-----------|
| 1 | comment, definition |
| 2 | keyword, string |
| 3 | type, constant, number, attribute, variable |
| 4 | function, operator, bracket, delimiter |

---

## テストの追加方法

### 新しいフォントロック検証を追加する

1. `test/testdata/font-lock.mbt`（または `.mbti`, `moon.pkg`）に MoonBit コードと `ert-font-lock` アノテーションを追記する

2. アノテーション位置を正確に計算する：
   - `^` は `//` を含む列番号でカウントする（0-indexed）
   - 確認したいソース文字の列番号 = アノテーション行の `^` の列番号

3. `make test` で確認する

### デバッグ: tree-sitter ノード確認

カーソル位置の face や node 型を対話的に確認するには：

```elisp
;; カーソル位置の face 確認
(get-text-property (point) 'face)

;; tree-sitter ノード型を確認
(treesit-node-type (treesit-node-at (point)))

;; パースツリーを視覚的に確認
M-x treesit-explore-mode
```

バッチモードでのデバッグ例：

```bash
emacs --batch -l moonbit-mode.el --eval '
(progn
  (find-file "test/testdata/font-lock.mbt")
  (moonbit-mode)
  (let ((treesit-font-lock-level 4))
    (treesit-font-lock-recompute-features)
    (font-lock-ensure))
  (goto-char (point-min))
  (forward-line 99)
  (let ((pos (+ (line-beginning-position) 16)))
    (message "face at col 16: %s" (get-text-property pos (quote face)))))
'
```

---

## トラブルシューティング

### `tree-sitter MoonBit grammar not available`

文法がインストールされていない場合、`moonbit-mode` のフォントロックテストは `skip-unless` で自動スキップされる。

手動インストール：

```elisp
(add-to-list 'treesit-language-source-alist
             '(moonbit "https://github.com/moonbitlang/tree-sitter-moonbit"))
;; M-x treesit-install-language-grammar RET moonbit RET
```

またはローカルソースから（ネットワーク不要）：

```elisp
(add-to-list 'treesit-language-source-alist
             `(moonbit ,(expand-file-name "refs/moonbitlang/tree-sitter-moonbit")))
(treesit-install-language-grammar 'moonbit)
```

### face が期待通りにならない

`treesit-font-lock-rules` の `:override` 指定が原因のことが多い：

| 状況 | 解決策 |
|------|--------|
| 親ノードの face が子ノードを上書きしている | 子ノードのルールを `:override t` で別ブロックに分離する |
| 先行ルールの face が後続ルールを妨げている | 後続ルールに `:override t` を指定するか、ルール順序を変更する |
| 同一ノードに複数ルールが競合している | より特定的なルールを先行させ、汎用ルールは後に置く |
| 親ノードの face が先にクリームし子が上書きできない | `:override 'keep'` を使い「空き位置のみ埋める」ようにする |

詳細は `docs/ja/knowledge.md` の「`:override` オプション」を参照。

---

## 参照

- tree-sitter MoonBit 文法: `refs/moonbitlang/tree-sitter-moonbit/`
- MoonBit 言語リファレンス: `refs/moonbitlang/moonbit-agent-guide/moonbit-agent-guide/references/`
  - `moonbit-language-fundamentals.md` — 言語の基本構文
  - `moonbit-language-fundamentals.mbt.md` — コード付き解説
  - `advanced-moonbit-build.md` — ビルドシステム
- `ert-font-lock` ドキュメント: `M-x describe-function RET ert-font-lock-test-file`
