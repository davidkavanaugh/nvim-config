-- lazygit in a terminal split for visually reviewing/staging changes.
--
-- <leader>git   toggle lazygit panel
--
-- Placement: if the Copilot CLI panel is open, lazygit opens immediately to
-- its left (so Copilot stays pinned to the far right). Otherwise lazygit
-- opens on the right with `botright vnew`.

local state = { buf = nil, win = nil, job = nil }

local function find_copilot_win()
    for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        local b = vim.api.nvim_win_get_buf(w)
        local ft = vim.bo[b].filetype
        if ft == "copilot_cli" or ft == "agency_copilot_cli" then
            return w
        end
    end
    return nil
end

local function open()
    local copilot_win = find_copilot_win()
    if copilot_win then
        vim.api.nvim_set_current_win(copilot_win)
        vim.cmd("leftabove vnew")
    else
        vim.cmd("botright vnew")
    end
    vim.cmd("vertical resize " .. math.floor(vim.o.columns * 0.4))
    state.win = vim.api.nvim_get_current_win()
    vim.wo[state.win].winfixwidth = true

    if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
        local empty = vim.api.nvim_get_current_buf()
        vim.api.nvim_win_set_buf(state.win, state.buf)
        pcall(vim.api.nvim_buf_delete, empty, { force = true })
    else
        state.job = vim.fn.termopen("lazygit", {
            cwd = vim.fn.getcwd(),
            on_exit = function()
                state.buf = nil
                state.job = nil
                if state.win and vim.api.nvim_win_is_valid(state.win) then
                    pcall(vim.api.nvim_win_close, state.win, true)
                end
                state.win = nil
                -- Refresh gitsigns / tree after lazygit exits so any changes
                -- it made are reflected in the editor immediately.
                pcall(vim.cmd, "checktime")
                local ok, gs = pcall(require, "gitsigns")
                if ok and gs.refresh then pcall(gs.refresh) end
                pcall(vim.cmd, "silent! NvimTreeRefresh")
            end,
        })
        state.buf = vim.api.nvim_get_current_buf()
        vim.bo[state.buf].filetype  = "lazygit"
        vim.bo[state.buf].buflisted = false
        vim.wo[state.win].number         = false
        vim.wo[state.win].relativenumber = false
        vim.wo[state.win].signcolumn     = "no"
    end

    vim.cmd("startinsert")
end

local function close()
    if state.win and vim.api.nvim_win_is_valid(state.win) then
        vim.api.nvim_win_close(state.win, true)
    end
    state.win = nil
end

local function toggle()
    if state.win and vim.api.nvim_win_is_valid(state.win) then
        close()
        return
    end
    if vim.fn.executable("lazygit") == 0 then
        vim.notify(
            "lazygit is not installed. Install via `winget install JesseDuffield.lazygit` or `scoop install lazygit`.",
            vim.log.levels.ERROR
        )
        return
    end
    open()
end

vim.keymap.set("n", "<leader>git", toggle, { desc = "Git: toggle lazygit" })
vim.keymap.set("t", "<leader>git", function()
    vim.cmd("stopinsert")
    toggle()
end, { desc = "Git: toggle lazygit" })

vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
    pattern = "*",
    callback = function()
        if vim.bo.filetype == "lazygit" then
            vim.cmd("startinsert")
        end
    end,
})
