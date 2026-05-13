# NVIM Configurations

Personal Neovim config, originally bootstrapped from ThePrimeagen's [0 to LSP: Neovim RC from Scratch](https://youtube.com/watch?v=w7i4amO_zaE&si=EnSIkaIECMiOmarE), now managed with [lazy.nvim](https://github.com/folke/lazy.nvim).

## Requirements

- Neovim >= 0.9 (tested on 0.11)
- [ripgrep](https://github.com/BurntSushi/ripgrep) (for Telescope live grep)
- A C compiler (for nvim-treesitter parsers)
- Git

## Install

Symlink (or clone) this repo into your Neovim config directory:

- **Linux / macOS:** `~/.config/nvim`
- **Windows:** `%LOCALAPPDATA%\nvim`

Launch `nvim`. On first start, `lazy.nvim` bootstraps itself and installs every plugin automatically. Use `:Lazy` to manage them and `:Mason` to install LSP servers.
