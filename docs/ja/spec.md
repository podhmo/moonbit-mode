# moonbit-mode.el

個人的なmoonbit用のemacsのmajor mode。

機能

- tree-sitterを利用したfont-lockの定義

参考

- 既存のemacsのmajor-modeは /Applications/Emacs.app/Contents/Resources/lisp/progmodes/typescript-ts-mode.el.gz に存在する
- refs/以下に参考になりそうなコードが存在する
    - moonbitのtree-sitterの実装は refs/moonbitlang/tree-sitter-moonbit
    - shikijs用のmoonbitのsyntax highlightの設定は refs/shikijs/textmate-grammars-themes/packages/tm-grammars/grammars/moonbit.json
    - 最もシンプルなtree-sitterの実装は refs/mini-python-mode
- moonbitのドキュメントは refs/moonbitlang/moonbit-docs 以下にある
