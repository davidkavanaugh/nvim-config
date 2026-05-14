-- Disable copilot's default <Tab> mapping so we can bind it explicitly below.
vim.g.copilot_no_tab_map = true

-- <Tab> in insert mode:
--   * If a Copilot ghost-text suggestion is visible, accept it
--   * Otherwise fall back to a literal <Tab>
vim.keymap.set("i", "<Tab>", function()
    if vim.fn["copilot#GetDisplayedSuggestion"]().text ~= "" then
        return vim.fn["copilot#Accept"]("")
    end
    return "<Tab>"
end, { expr = true, replace_keycodes = false, silent = true, desc = "Copilot accept or tab" })

-- Useful follow-ups
vim.keymap.set("i", "<C-]>", "<Plug>(copilot-dismiss)",   { desc = "Copilot dismiss" })
vim.keymap.set("i", "<M-]>", "<Plug>(copilot-next)",      { desc = "Copilot next suggestion" })
vim.keymap.set("i", "<M-[>", "<Plug>(copilot-previous)",  { desc = "Copilot prev suggestion" })
