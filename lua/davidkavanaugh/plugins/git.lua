-- Git UI: Neogit (status panel) + Diffview (side-by-side diffs) + git-conflict (merge conflict UX)
return {
    -- Neogit: magit-style status panel showing staged / unstaged / untracked
    -- files with inline keybindings to stage (s), unstage (u), discard (x),
    -- commit (cc), push (Pp), pull (Pl), etc.
    {
        "NeogitOrg/neogit",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "sindrets/diffview.nvim",
            "nvim-telescope/telescope.nvim",
        },
        cmd = { "Neogit" },
        keys = {
            { "<leader>gc",  "<cmd>Neogit commit<cr>",     desc = "Git: commit" },
            { "<leader>gp",  "<cmd>Neogit push<cr>",       desc = "Git: push" },
            { "<leader>gP",  "<cmd>Neogit pull<cr>",       desc = "Git: pull" },
            { "<leader>gl",  "<cmd>Neogit log<cr>",        desc = "Git: log" },
            { "<leader>gd",  "<cmd>DiffviewOpen<cr>",      desc = "Git: diffview (working tree)" },
            { "<leader>gD",  "<cmd>DiffviewClose<cr>",     desc = "Git: diffview close" },
            { "<leader>gh",  "<cmd>DiffviewFileHistory %<cr>", desc = "Git: file history (current file)" },
            { "<leader>gH",  "<cmd>DiffviewFileHistory<cr>",   desc = "Git: file history (repo)" },
        },
        opts = {
            kind = "tab", -- open the status panel in its own tab for a full-screen UI
            disable_commit_confirmation = false,
            integrations = {
                diffview = true,
                telescope = true,
            },
            signs = {
                section = { "", "" },
                item    = { "", "" },
                hunk    = { "", "" },
            },
            -- Use 2-pane diff inside Neogit's diff popup
            commit_editor = { kind = "tab" },
            commit_view = { kind = "vsplit" },
            popup = { kind = "split" },
        },
    },

    -- Diffview: rich side-by-side diff for the working tree, commits, history
    {
        "sindrets/diffview.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        cmd = {
            "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles",
            "DiffviewFocusFiles", "DiffviewFileHistory", "DiffviewRefresh",
        },
        opts = {
            enhanced_diff_hl = true,
            view = {
                merge_tool = {
                    -- 3-way merge: OURS | BASE | THEIRS  with RESULT below
                    layout = "diff3_mixed",
                    disable_diagnostics = true,
                },
            },
            file_panel = {
                listing_style = "tree",
                win_config = { position = "left", width = 35 },
            },
        },
    },

    -- git-conflict: highlights conflict markers and provides quick resolution.
    -- Inside a conflict:
    --   co - choose ours          ct - choose theirs
    --   cb - choose both          c0 - choose none
    --   ]x / [x - next / prev conflict
    --   <leader>gx - quickfix list of all conflicts in repo
    {
        "akinsho/git-conflict.nvim",
        version = "*",
        event = "BufReadPre",
        opts = {
            default_mappings = true,
            default_commands = true,
            disable_diagnostics = false,
            list_opener = "copen",
            highlights = {
                incoming = "DiffAdd",
                current  = "DiffText",
            },
        },
        keys = {
            { "<leader>gx", "<cmd>GitConflictListQf<cr>",     desc = "Git: list merge conflicts" },
            { "<leader>gr", "<cmd>GitConflictRefresh<cr>",    desc = "Git: refresh conflict markers" },
            { "]x",         "<cmd>GitConflictNextConflict<cr>", desc = "Git: next conflict" },
            { "[x",         "<cmd>GitConflictPrevConflict<cr>", desc = "Git: prev conflict" },
        },
    },
}
