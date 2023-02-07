vim.g.tmux_navigator_no_mappings = 1
vim.g.tmux_navigator_disable_when_zoomed = 1

-- easier split nav
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { noremap = true })
vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { noremap = true })
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { noremap = true })
vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { noremap = true })

-- nav to tmux panes
vim.keymap.set("n", "<C-h>", vim.cmd.TmuxNavigateLeft, { noremap = true, silent = true })
vim.keymap.set("n", "<C-j>", vim.cmd.TmuxNavigateDown, { noremap = true, silent = true })
vim.keymap.set("n", "<C-k>", vim.cmd.TmuxNavigateUp, { noremap = true, silent = true })
vim.keymap.set("n", "<C-l>", vim.cmd.TmuxNavigateRight, { noremap = true, silent = true })

