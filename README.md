# moonbit-mode

Emacs major mode for the [MoonBit](https://www.moonbitlang.com/) programming language, powered by Emacs's built-in tree-sitter support (Emacs 30+).

## Features

- **Syntax highlighting** (font-lock) via tree-sitter for `.mbt`, `.mbti`, `.mbtx`, and `moon.pkg` files
- **Imenu** — jump to functions, structs, enums, traits, types, impls, constants, and tests
- **Flymake** integration — real-time diagnostics via `moon check --output-json`

## Requirements

- Emacs 30 or later (built-in tree-sitter support)
- [MoonBit toolchain](https://www.moonbitlang.com/download/) (`moon` command in `PATH`)
- tree-sitter MoonBit grammar

## Installation

### 1. Install the tree-sitter grammar

Add to your init file and run `M-x treesit-install-language-grammar RET moonbit RET`:

```elisp
(add-to-list 'treesit-language-source-alist
             '(moonbit "https://github.com/moonbitlang/tree-sitter-moonbit"))
```

### 2. Load moonbit-mode

```elisp
(require 'moonbit-mode)
```

Or with `use-package`:

```elisp
(use-package moonbit-mode
  :load-path "/path/to/moonbit-mode")
```

## Flymake

Flymake support uses `moon check --output-json` run at the project root (the directory containing `moon.mod.json`).

Enable it manually:

```elisp
M-x flymake-mode
```

Or enable automatically for all MoonBit buffers:

```elisp
(add-hook 'moonbit-mode-hook #'flymake-mode)
(add-hook 'moonbit-mode-hook #'eldoc-mode)
```

The command can be customized via `moonbit-flymake-command`:

```elisp
(setq moonbit-flymake-command '("moon" "check" "--output-json" "--deny-warn"))
```

## Running tests

```bash
make test
```

See [docs/ja/testing.md](docs/ja/testing.md) for details.
