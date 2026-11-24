This is the distro neovim for fullstack development.

🚀 Performance: Fast startup with lazy loading (built on [lazy.nvim](https://github.com/folke/lazy.nvim))

## Features

| Plugin                                                                                                               | Description                                                                                        |
| -------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| [lazy.nvim](https://github.com/folke/lazy.nvim)                                                                      | Plugin manager that loads plugins lazily for fast startup.                                         |
| [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)                                                | Syntax highlighting, indentation, folds, and on-demand parser installation.                        |
| [render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim)                                 | Render markdown with visual enhancements.                                                          |
| [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)                                                           | LSP configurations for lua, python, web, java, bash, c/c++, go, zig, rust, and more.               |
| [mason.nvim](https://github.com/mason-org/mason.nvim)                                                                | Automatically installs LSP servers, formatters, linters, and debug adapters.                       |
| [mason-scout](https://github.com/sontungexpt/mason-scout)                                                            | Scout for missing mason packages.                                                                  |
| [rustaceanvim](https://github.com/mrcjkb/rustaceanvim)                                                               | Rust LSP and debugging integration.                                                                |
| [nvim-jdtls](https://github.com/mfussenegger/nvim-jdtls)                                                             | Java LSP (jdtls) integration.                                                                      |
| [conform.nvim](https://github.com/stevearc/conform.nvim)                                                             | Fast formatter with format-on-save support.                                                        |
| [blink.cmp](https://github.com/saghen/blink.cmp)                                                                     | Modern autocompletion with LSP, path, buffer, and snippets sources.                                |
| [which-key.nvim](https://github.com/folke/which-key.nvim)                                                            | Keymap hint layer.                                                                                 |
| [snacks.nvim](https://github.com/folke/snacks.nvim)                                                                  | UI suite: picker, explorer, notifier, dashboard, scope, words, and more.                           |
| [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim)                                                          | Git signs, blame, hunk navigation, and conflict resolution.                                        |
| [git-conflict.nvim](https://github.com/akinsho/git-conflict.nvim)                                                    | Git conflict resolution UI.                                                                        |
| [Comment.nvim](https://github.com/numToStr/Comment.nvim)                                                             | Easy commenting with treesitter context awareness.                                                 |
| [indent-blankline.nvim](https://github.com/lukas-reineke/indent-blankline.nvim)                                      | Indentation guides with scope highlighting.                                                        |
| [ccc.nvim](https://github.com/uga-rosa/ccc.nvim)                                                                     | Color picker.                                                                                      |
| [nvim-highlight-colors](https://github.com/brenoprata10/nvim-highlight-colors)                                       | Highlight color hex codes in buffers.                                                              |
| [smart-resizing](https://github.com/sontungexpt/smart-resizing)                                                      | Resize windows with arrow keys.                                                                    |
| [nvim-dap](https://github.com/mfussenegger/nvim-dap), [nvim-dap-ui](https://github.com/rcarriga/nvim-dap-ui)           | Debugging with DAP, DAP-UI, and virtual text.                                                      |
| [witch](https://github.com/sontungexpt/witch) / [witch-line](https://github.com/sontungexpt/witch-line)                | Main theme and statusline.                                                                         |
| [vietnamese.nvim](https://github.com/sontungexpt/vietnamese.nvim)                                                    | Vietnamese input method (IME) support.                                                             |

## Requirements

- Nerdfonts (for icons) (I use Hack Nerd Font)
- Neovim 0.10 or higher

Arch Linux:

```bash
yay -S ttf-hack-nerd
```

## Installation

Clone this repository into your Neovim configuration directory.

Linux and MacOS:

SSH method (recommended)

```bash
[ -d ~/.config/nvim ] && mv ~/.config/nvim ~/.config/nvim.bak ; git clone git@github.com:sontungexpt/stinvim.git ~/.config/nvim --depth 1
```

```bash
[ -d ~/.config/nvim ] && mv ~/.config/nvim ~/.config/nvim.bak ; git clone https://github.com/sontungexpt/stinvim.git ~/.config/nvim --depth 1
```

Windows (git bash)

```bash
[ -d %USERPROFILE%/Local/nvim ] && mv %USERPROFILE%\AppData\Local\nvim %USERPROFILE%\AppData\Local\nvim.bak ; git clone https://github.com/sontungexpt/stinvim.git %USERPROFILE%\AppData\Local\nvim --depth 1
```

You will also need to install the plugins. This configuration uses the lazy.nvim plugin manager to manage plugins. You can install the plugins by opening Neovim and running `:Lazy sync`.

```vim
:Lazy sync
```

## Inspiration

- [neovim-config](https://github.com/sontungexpt/neovim-config)

## Configuration

This configuration is highly customizable and easy to configure.

## Contributions

If you find any issues with this configuration or would like to contribute, please feel free to submit a pull request or open an issue.

## License

This configuration is licensed under the MIT license - see the [LICENSE](LICENSE) file for details.
