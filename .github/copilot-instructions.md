# Copilot Instructions

Personal Neovim configuration, managed with [lazy.nvim](https://github.com/folke/lazy.nvim). Targets Neovim >= 0.9 (developed/tested on 0.11). See `README.md` for install instructions.

## How the config loads

Load order is important — changes must respect it:

1. `init.lua` (repo root) → `require("davidkavanaugh")`.
2. `lua/davidkavanaugh/init.lua` requires, in order: `set` (vim options), `remap` (global keymaps), `lazy` (bootstraps lazy.nvim and plugin loading). It also defines the `ThePrimeagen` and `HighlightYank` autocmd groups, including a `BufWritePre *` autocmd that strips trailing whitespace from every saved file.
3. `lua/davidkavanaugh/lazy.lua` bootstraps `lazy.nvim` and calls `require("lazy").setup("davidkavanaugh.plugins", ...)`. This loads the plugin **spec** from `lua/davidkavanaugh/plugins/` (any module returning a spec list — currently `init.lua` and `git.lua` — is merged).
4. After all plugins are installed, Neovim sources every file under `after/plugin/` alphabetically. These contain **plugin configuration** (setup calls, keymaps, options) — not plugin declarations.

When adding a plugin:
- Declare it in a file under `lua/davidkavanaugh/plugins/` (return a lazy.nvim spec table). Co-locate related plugins (e.g. all git plugins live in `git.lua`).
- If the plugin needs imperative setup beyond `opts =`/`config =`, add a corresponding `after/plugin/<name>.lua` file.
- Prefer the lazy.nvim `keys = { ... }` form for lazy-loaded plugins so they load on first use; use `after/plugin/*.lua` only for plugins that need eager setup.

## Plugin manager & dependencies

- `lazy-lock.json` pins exact plugin commits — commit it whenever you run `:Lazy update` / `:Lazy sync`.
- LSP servers, formatters, and linters are managed by **Mason** (`:Mason`), not by this repo. Required servers are listed in `mason-lspconfig`'s `ensure_installed` in `after/plugin/lsp.lua`.
- Treesitter is pinned to the `master` branch on purpose — the `main` branch dropped the legacy configs API this config uses. Don't switch it.

## LSP conventions (`after/plugin/lsp.lua`)

- Uses the **Neovim 0.11 native `vim.lsp.config` / `vim.lsp.enable` API** via `mason-lspconfig` v2's `automatic_enable = true`. Do not reintroduce `lspconfig[server].setup{}` calls or `lsp-zero` — they conflict with this setup.
- Per-server overrides go through `vim.lsp.config("<server>", { ... })`. Global defaults (e.g. cmp capabilities) use `vim.lsp.config("*", { ... })`.
- The `eslint` LSP client is intentionally stopped on `LspAttach` — eslint is kept in `ensure_installed` only to install the binary; it is not used as a running language server.
- All buffer-local LSP keymaps are set inside the single `LspAttach` autocmd. Add new LSP keymaps there, not in `remap.lua`.

## Keymap conventions

- Leader is `<Space>` (set in `remap.lua`, must be set before any plugin loads).
- Global, non-plugin keymaps live in `lua/davidkavanaugh/remap.lua`.
- Plugin keymaps live with the plugin: either in the spec's `keys = { ... }` (preferred for lazy loading) or in the corresponding `after/plugin/*.lua` file.
- Buffer-local LSP keymaps live in the `LspAttach` callback in `after/plugin/lsp.lua`.
- `<leader>c*` is reserved for Copilot Chat, `<leader>g*` for git (Neogit/Diffview/Fugitive/git-conflict), `<leader>v*` for LSP actions, `<leader>x*` for Trouble.

## Editor invariants set in `set.lua`

These are assumed by other parts of the config — change with care:
- 4-space expandtab indentation everywhere (no per-filetype overrides currently).
- `undofile = true` with undodir at `$HOME/.vim/undodir` (or `$USERPROFILE` on Windows) — this directory must exist or undo persistence silently fails.
- `autoread = true` is intentional so external tools (e.g. the Copilot CLI side panel changing branches) are reflected without manual `:e`.
- `swapfile`/`backup` are off; rely on undofile + git.

## Cross-platform notes

This config is used on both Windows and Unix. When touching paths or shell-outs:
- Use `os.getenv("HOME") or os.getenv("USERPROFILE")` for the home directory (see `set.lua`).
- Use `vim.uv or vim.loop` for libuv access (see `lazy.lua`) — `vim.uv` doesn't exist on older Neovim.
- Don't hardcode `/` vs `\`; let Neovim/lazy handle path joining.

## Verifying changes

There is no test suite or CI. After edits:
- `nvim --headless "+checkhealth" +qa` to surface obvious load errors.
- Launch `nvim`, run `:Lazy sync` and `:checkhealth`, and confirm `:messages` is clean.
- For LSP changes, open a file of the relevant language and check `:LspInfo` / `:Mason`.
