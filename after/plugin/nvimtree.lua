-- disable netrw at the very start of your init.lua (strongly advised)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- set termguicolors to enable highlight groups
vim.opt.termguicolors = true

require'nvim-web-devicons'.setup()

-- empty setup using defaults
require("nvim-tree").setup()

vim.keymap.set("n", "<leader>pe", vim.cmd.NvimTreeToggle)
vim.keymap.set("n", "<leader>pef", vim.cmd.NvimTreeFindFile)

