-- Run the real GitHub Copilot CLI in a vertical terminal split.
-- Gives 100% UX parity with the standalone `copilot` CLI - no plugin layer.
--
-- <leader>cp    toggle the Copilot CLI side panel
-- <leader>acp   toggle the Agency Copilot CLI side panel
--
-- Branch sync:
--   * CLI inherits nvim's CWD on open, so it starts on the same branch.
--   * While the panel is open we watch `.git/HEAD` for changes; the instant
--     the CLI (or anything else) checks out a different branch, the editor
--     reloads any modified buffers and refreshes gitsigns / NvimTree.

local M = {}

local function new_state()
    return { buf = nil, win = nil, job = nil, head_watcher = nil, head_path = nil }
end

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

local function start_head_watcher(state)
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

local function stop_head_watcher(state)
    if state.head_watcher then
        pcall(function() state.head_watcher:stop() end)
        pcall(function() state.head_watcher:close() end)
        state.head_watcher = nil
    end
end

local function open(state, cmd, filetype)
    vim.cmd("botright vnew")
    vim.cmd("vertical resize " .. math.floor(vim.o.columns * 0.4))
    state.win = vim.api.nvim_get_current_win()
    -- Keep the panel pinned to the right at its current width.
    vim.wo[state.win].winfixwidth = true

    if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
        local empty = vim.api.nvim_get_current_buf()
        vim.api.nvim_win_set_buf(state.win, state.buf)
        pcall(vim.api.nvim_buf_delete, empty, { force = true })
    else
        state.job = vim.fn.termopen(cmd, {
            cwd = vim.fn.getcwd(),
            on_exit = function()
                state.buf = nil
                state.job = nil
                stop_head_watcher(state)
            end,
        })
        state.buf = vim.api.nvim_get_current_buf()
        vim.bo[state.buf].filetype  = filetype
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

    start_head_watcher(state)
    vim.cmd("startinsert")
end

local function close(state)
    if state.win and vim.api.nvim_win_is_valid(state.win) then
        vim.api.nvim_win_close(state.win, true)
    end
    state.win = nil
    -- Keep the watcher running while the CLI job is alive so backgrounded
    -- branch changes still propagate. It will be torn down on job exit.
end

local function resize_state(state, pct)
    if not (state.win and vim.api.nvim_win_is_valid(state.win)) then return end
    if not (state.buf and vim.api.nvim_buf_is_valid(state.buf)) then return end

    local width = math.floor(vim.o.columns * pct)
    local was_insert = vim.api.nvim_get_mode().mode:sub(1, 1) == "t"

    -- Resize the window in place. The previous implementation closed and
    -- reopened the window because nvim_win_set_width alone left stale
    -- wrapped scrollback visible - but the underlying cause was that no
    -- SIGWINCH was being sent to the PTY, so Ink never repainted. With an
    -- explicit jobresize the in-place resize works correctly and avoids
    -- the close/reopen flicker entirely.
    pcall(vim.api.nvim_win_set_width, state.win, width)

    local function nudge()
        if not (state.win and vim.api.nvim_win_is_valid(state.win)) then return end
        if not (state.buf and vim.api.nvim_buf_is_valid(state.buf)) then return end
        if state.job and state.job > 0 then
            local w = vim.api.nvim_win_get_width(state.win)
            local h = vim.api.nvim_win_get_height(state.win)
            pcall(vim.fn.jobresize, state.job, w, h)
        end
        -- Anchor the viewport on Ink's live frame at the bottom of the
        -- terminal buffer (scrollback above may still show wrapped lines
        -- from the previous width).
        local line_count = vim.api.nvim_buf_line_count(state.buf)
        pcall(vim.api.nvim_win_set_cursor, state.win, { line_count, 0 })
        pcall(vim.cmd, "redraw!")
        if was_insert then vim.cmd("startinsert") end
    end

    -- Send SIGWINCH on the next tick (after the window has settled at the
    -- new width), then again ~80ms later to catch Ink if it debounced the
    -- first one during its own paint cycle.
    vim.schedule(nudge)
    vim.defer_fn(nudge, 80)
    vim.defer_fn(nudge, 200)
end

local function make_panel(opts)
    local state = new_state()
    local panel = {}

    function panel.toggle()
        if state.win and vim.api.nvim_win_is_valid(state.win) then
            close(state)
        else
            open(state, opts.cmd, opts.filetype)
        end
    end

    function panel.resize(pct)
        resize_state(state, pct)
    end

    panel._state = state
    return panel
end

M.copilot = make_panel({ cmd = "copilot", filetype = "copilot_cli" })
M.agency  = make_panel({ cmd = "agency copilot", filetype = "agency_copilot_cli" })

-- Back-compat: top-level resize/toggle drive the Copilot CLI panel.
M.toggle = M.copilot.toggle
M.resize = M.copilot.resize

vim.keymap.set("n", "<leader>cp", M.copilot.toggle, { desc = "Toggle Copilot CLI" })
vim.keymap.set("t", "<leader>cp", function()
    vim.cmd("stopinsert")
    M.copilot.toggle()
end, { desc = "Toggle Copilot CLI" })

vim.keymap.set("n", "<leader>acp", M.agency.toggle, { desc = "Toggle Agency Copilot CLI" })
vim.keymap.set("t", "<leader>acp", function()
    vim.cmd("stopinsert")
    M.agency.toggle()
end, { desc = "Toggle Agency Copilot CLI" })

local function resize_active(pct)
    if M.agency._state.win and vim.api.nvim_win_is_valid(M.agency._state.win) then
        M.agency.resize(pct)
    else
        M.copilot.resize(pct)
    end
end

vim.keymap.set("n", "<M-=>", function() resize_active(0.8) end, { desc = "Copilot CLI: expand to 80%" })
vim.keymap.set("n", "<M-->", function() resize_active(0.4) end, { desc = "Copilot CLI: shrink to 40%" })
vim.keymap.set("t", "<M-=>", function() resize_active(0.8) end, { desc = "Copilot CLI: expand to 80%" })
vim.keymap.set("t", "<M-->", function() resize_active(0.4) end, { desc = "Copilot CLI: shrink to 40%" })

vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
    pattern = "*",
    callback = function()
        local ft = vim.bo.filetype
        if ft == "copilot_cli" or ft == "agency_copilot_cli" then
            vim.cmd("startinsert")
        end
    end,
})

-- Keep the Copilot CLI panel pinned to the far right: if any other buffer
-- ends up displayed in the panel window (e.g. `:edit somefile` issued while
-- focus is in the panel, or a picker that targeted the wrong window), shove
-- it into a window to the left and restore the terminal in the panel slot.
local function find_main_win(panel_win)
    for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if w ~= panel_win and vim.api.nvim_win_get_config(w).relative == "" then
            local b = vim.api.nvim_win_get_buf(w)
            local bt = vim.bo[b].buftype
            local ft = vim.bo[b].filetype
            if bt == "" and ft ~= "NvimTree" and ft ~= "neo-tree" then
                return w
            end
        end
    end
    return nil
end

local function relocate_intruder(state, intruder_buf)
    if not (state.win and vim.api.nvim_win_is_valid(state.win)) then return end
    if not (state.buf and vim.api.nvim_buf_is_valid(state.buf)) then return end
    if intruder_buf == state.buf then return end

    -- Restore the terminal buffer in the panel window.
    pcall(vim.api.nvim_win_set_buf, state.win, state.buf)

    -- Send the file buffer to a window on the left, creating one if needed.
    local target = find_main_win(state.win)
    if target then
        vim.api.nvim_win_set_buf(target, intruder_buf)
        vim.api.nvim_set_current_win(target)
    else
        local prev = vim.api.nvim_get_current_win()
        vim.api.nvim_set_current_win(state.win)
        vim.cmd("leftabove vsplit")
        vim.api.nvim_win_set_buf(0, intruder_buf)
        if not vim.api.nvim_win_is_valid(prev) then prev = 0 end
    end
end

vim.api.nvim_create_autocmd("BufWinEnter", {
    callback = function(args)
        local ft = vim.bo[args.buf].filetype
        if ft == "copilot_cli" or ft == "agency_copilot_cli" then return end
        for _, panel in ipairs({ M.copilot, M.agency }) do
            local state = panel._state
            if state.win and vim.api.nvim_win_is_valid(state.win)
                and vim.api.nvim_win_get_buf(state.win) == args.buf then
                vim.schedule(function() relocate_intruder(state, args.buf) end)
                return
            end
        end
    end,
})

vim.api.nvim_create_autocmd("FocusGained", {
    callback = refresh_editor_for_branch_change,
})

return M


