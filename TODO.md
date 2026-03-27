# TODO: moonbit-mode.el

spec.md をもとにした実装タスク一覧。

- [X] Font-lock（.mbt）
- [X] Imenu -- `treesit-simple-imenu-settings` で以下の定義一覧を提供:
  - Struct: `struct_definition`,Enum: `enum_definition`, Trait: `trait_definition`,- Type: `type_definition`, Impl: `impl_definition`, Const: `const_definition`, Test: `test_definition`
- [X] `define-derived-mode moonbit-mode prog-mode`
- [X] コメント設定 (`comment-start` = `"// "`)
- [X] シンタックステーブルの定義
- [X] `auto-mode-alist` への `.mbt` 登録
- [X] `treesit-ready-p` チェック付き初期化
- [ ] テストコードの追加
- [ ] README.mdの作成
    - [ ] 提供されてる機能一覧
    - [ ] 設定方法
    - [ ] テストの実行方法 (via docs/ja/testing.md)
- [ ] Font-lock .mbti サポート（インターフェースファイル）
    - `.mbti` は `.mbt` と同じ `moonbit` grammar を使用（別 grammar 不要）
    - body なし宣言（`fn[T] abort(String) -> T`、`impl Show for Int` 等）に対応済み
    - `auto-mode-alist` への `.mbti` 登録のみで動作するはず
      ```elisp
      (add-to-list 'auto-mode-alist '("\\.mbti\\'" . moonbit-mode))
      ```
- [ ] Font-lock moon.pkg サポート（パッケージマニフェスト）
    - `moon.pkg` も同じ `moonbit` grammar を使用（assignment / apply statement 形式）
    - `auto-mode-alist` へのファイル名ベース登録が必要（拡張子ではなくファイル名）
      ```elisp
      (add-to-list 'auto-mode-alist '("/moon\\.pkg\\'" . moonbit-mode))
   ```

- [ ] インデント `treesit-simple-indent-rules` の実装
     - ブロック / match / if-else / 引数リスト等 (正確に調べてから実装する)
