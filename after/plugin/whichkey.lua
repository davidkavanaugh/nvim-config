local wk = require("which-key")

wk.setup({
    preset = "modern",
    delay = 300,
    icons = { mappings = false },
})

-- Register descriptions for leader-prefixed groups so the popup reads nicely.
wk.add({
    { "<leader>p",  group = "project / find" },
    { "<leader>v",  group = "lsp" },
    { "<leader>x",  group = "trouble" },
    { "<leader>h",  group = "git hunks" },
    { "<leader>t",  group = "toggle" },
    { "<leader>g",  group = "git" },
    { "<leader>y",  desc  = "yank to system clipboard" },
    { "<leader>Y",  desc  = "yank line to system clipboard" },
    { "<leader>d",  desc  = "delete to void register" },
    { "<leader>f",  desc  = "lsp format" },
    { "<leader>s",  desc  = "substitute word under cursor" },
    { "<leader>a",  desc  = "harpoon add file" },
})
