-- Run the real GitHub Copilot CLI in a vertical terminal split.
-- Gives 100% UX parity with the standalone `copilot` CLI - no plugin layer.
--
-- <leader>cp   toggle the Copilot CLI side panel
--
-- The CLI inherits nvim's CWD on open, so it starts on the same git branch
-- as the editor. Whenever you leave the CLI panel (or nvim regains focus),
-- the editor reloads any changed files and refreshes gitsigns so the
-- left-hand view tracks branches you switch to inside the CLI.

local M = {}

local state = { buf = nil, win = nil, job = nil }

local function refresh_editor_for_branch_change()
    -- Reload any open buffers whose underlying file changed on disk
    pcall(vim.cmd, "checktime")
    -- Re-detect git HEAD / blame / hunks
    local ok, gs = pcall(require, "gitsigns")
    if ok and gs.refresh then pcall(gs.refresh) end
    -- Refresh nvim-tree if present
    pcall(vim.cmd, "silent! NvimTreeRefresh")
end

local function open()
    -- `vnew` = vertical split + brand new empty buffer (avoids E5108 from
    -- trying to termopen into NvimTree's or any other non-empty buffer).
    vim.cmd("botright vnew")
    vim.cmd("vertical resize " .. math.floor(vim.o.columns * 0.4))
    state.win = vim.api.nvim_get_current_win()

    if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
        -- Reuse the existing CLI session: swap fresh empty buf for the live one
        local empty = vim.api.nvim_get_current_buf()
        vim.api.nvim_win_set_buf(state.win, state.buf)
        pcall(vim.api.nvim_buf_delete, empty, { force = true })
    else
        -- Spin up a fresh CLI session in nvim's CWD (so it starts on the
        -- same git branch as the editor)
        state.job = vim.fn.termopen("copilot", {
            cwd = vim.fn.getcwd(),
            on_exit = function()
                state.buf = nil
                state.job = nil
            end,
        })
        state.buf = vim.api.nvim_get_current_buf()
        vim.bo[state.buf].filetype  = "copilot_cli"
        vim.bo[state.buf].buflisted = false
        vim.wo[state.win].number         = false
        vim.wo[state.win].relativenumber = false
        vim.wo[state.win].signcolumn     = "no"

        -- When the user leaves this panel (typically to act on something the
        -- CLI just did, e.g. switched branches), reload the editor side.
        vim.api.nvim_create_autocmd("WinLeave", {
            buffer = state.buf,
            callback = function()
                vim.schedule(refresh_editor_for_branch_change)
            end,
        })
    end

    vim.cmd("startinsert")
end

local function close()
    if state.win and vim.api.nvim_win_is_valid(state.win) then
        vim.api.nvim_win_close(state.win, true)
    end
    state.win = nil
end

function M.toggle()
    if state.win and vim.api.nvim_win_is_valid(state.win) then
        close()
    else
        open()
    end
end

vim.keymap.set("n", "<leader>cp", M.toggle, { desc = "Toggle Copilot CLI" })
-- Same toggle from inside the CLI panel (terminal-mode)
vim.keymap.set("t", "<leader>cp", function()
    vim.cmd("stopinsert")
    M.toggle()
end, { desc = "Toggle Copilot CLI" })

-- Auto-enter insert (terminal) mode whenever you focus the CLI panel
vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
    pattern = "*",
    callback = function()
        if vim.bo.filetype == "copilot_cli" then
            vim.cmd("startinsert")
        end
    end,
})

-- Belt-and-suspenders: when nvim regains OS focus (e.g. after you alt-tabbed
-- away to do something git-related), also refresh.
vim.api.nvim_create_autocmd("FocusGained", {
    callback = refresh_editor_for_branch_change,
})

return M

