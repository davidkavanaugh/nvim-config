-- Run the real GitHub Copilot CLI in a vertical terminal split.
-- Gives 100% UX parity with the standalone `copilot` CLI - no plugin layer.
--
-- <leader>cp   toggle the Copilot CLI side panel
--
-- Branch sync:
--   * CLI inherits nvim's CWD on open, so it starts on the same branch.
--   * While the panel is open we watch `.git/HEAD` for changes; the instant
--     the CLI (or anything else) checks out a different branch, the editor
--     reloads any modified buffers and refreshes gitsigns / NvimTree.

local M = {}

local state = { buf = nil, win = nil, job = nil, head_watcher = nil, head_path = nil }

local function refresh_editor_for_branch_change()
    pcall(vim.cmd, "checktime")
    local ok, gs = pcall(require, "gitsigns")
    if ok and gs.refresh then pcall(gs.refresh) end
    pcall(vim.cmd, "silent! NvimTreeRefresh")
    pcall(vim.cmd, "silent! redrawstatus!")
end

local function git_head_path()
    local cwd = vim.fn.getcwd()
    local out = vim.fn.systemlist({ "git", "-C", cwd, "rev-parse", "--git-dir" })
    if vim.v.shell_error ~= 0 or not out or not out[1] then return nil end
    local gitdir = out[1]
    if not vim.startswith(gitdir, "/") and not gitdir:match("^%a:") then
        gitdir = cwd .. "/" .. gitdir
    end
    return gitdir .. "/HEAD"
end

local function start_head_watcher()
    if state.head_watcher then return end
    local head = git_head_path()
    if not head or vim.fn.filereadable(head) == 0 then return end
    state.head_path = head

    local w = vim.uv.new_fs_event()
    if not w then return end
    state.head_watcher = w
    w:start(head, {}, function(err)
        if err then return end
        vim.schedule(refresh_editor_for_branch_change)
        -- fs_event drops the watch on some filesystems after one event;
        -- re-arm by restarting on the same path.
        pcall(function() w:stop() end)
        pcall(function()
            w:start(head, {}, function()
                vim.schedule(refresh_editor_for_branch_change)
            end)
        end)
    end)
end

local function stop_head_watcher()
    if state.head_watcher then
        pcall(function() state.head_watcher:stop() end)
        pcall(function() state.head_watcher:close() end)
        state.head_watcher = nil
    end
end

local function open()
    vim.cmd("botright vnew")
    vim.cmd("vertical resize " .. math.floor(vim.o.columns * 0.4))
    state.win = vim.api.nvim_get_current_win()

    if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
        local empty = vim.api.nvim_get_current_buf()
        vim.api.nvim_win_set_buf(state.win, state.buf)
        pcall(vim.api.nvim_buf_delete, empty, { force = true })
    else
        state.job = vim.fn.termopen("copilot", {
            cwd = vim.fn.getcwd(),
            on_exit = function()
                state.buf = nil
                state.job = nil
                stop_head_watcher()
            end,
        })
        state.buf = vim.api.nvim_get_current_buf()
        vim.bo[state.buf].filetype  = "copilot_cli"
        vim.bo[state.buf].buflisted = false
        vim.wo[state.win].number         = false
        vim.wo[state.win].relativenumber = false
        vim.wo[state.win].signcolumn     = "no"

        -- Also refresh whenever you leave the panel - belt and braces
        vim.api.nvim_create_autocmd("WinLeave", {
            buffer = state.buf,
            callback = function() vim.schedule(refresh_editor_for_branch_change) end,
        })
    end

    start_head_watcher()
    vim.cmd("startinsert")
end

local function close()
    if state.win and vim.api.nvim_win_is_valid(state.win) then
        vim.api.nvim_win_close(state.win, true)
    end
    state.win = nil
    -- Keep the watcher running while the CLI job is alive so backgrounded
    -- branch changes still propagate. It will be torn down on job exit.
end

function M.toggle()
    if state.win and vim.api.nvim_win_is_valid(state.win) then
        close()
    else
        open()
    end
end

vim.keymap.set("n", "<leader>cp", M.toggle, { desc = "Toggle Copilot CLI" })
vim.keymap.set("t", "<leader>cp", function()
    vim.cmd("stopinsert")
    M.toggle()
end, { desc = "Toggle Copilot CLI" })

vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
    pattern = "*",
    callback = function()
        if vim.bo.filetype == "copilot_cli" then
            vim.cmd("startinsert")
        end
    end,
})

vim.api.nvim_create_autocmd("FocusGained", {
    callback = refresh_editor_for_branch_change,
})

return M


