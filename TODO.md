# TODO: moonbit-mode.el

spec.md をもとにした実装タスク一覧。

- [X] Font-lock（.mbt）
- [X] Font-lock（.mbti）
- [X] Font-lock（moon.pkg）
- [X] Imenu -- `treesit-simple-imenu-settings` で以下の定義一覧を提供:
  - Struct: `struct_definition`,Enum: `enum_definition`, Trait: `trait_definition`,- Type: `type_definition`, Impl: `impl_definition`, Const: `const_definition`, Test: `test_definition`
- [X] コメント設定 (`comment-start` = `"// "`)
- [ ] README.mdの作成
    - [ ] 提供されてる機能一覧
    - [ ] 設定方法
    - [ ] テストの実行方法 (via docs/ja/testing.md)
- [ ] インデント `treesit-simple-indent-rules` の実装
     - ブロック / match / if-else / 引数リスト等 (正確に調べてから実装する)
