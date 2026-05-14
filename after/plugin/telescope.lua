local telescope = require("telescope")
local builtin = require("telescope.builtin")
local lga = require("telescope-live-grep-args.shortcuts")

telescope.setup({
    defaults = {
        -- Force case-insensitive grep across the board; users can override
        -- per-search with --case-sensitive / -s via live-grep-args.
        vimgrep_arguments = {
            "rg",
            "--color=never",
            "--no-heading",
            "--with-filename",
            "--line-number",
            "--column",
            "--ignore-case",
        },
    },
    pickers = {
        current_buffer_fuzzy_find = { case_mode = "ignore_case" },
        find_files = { hidden = true },
    },
    extensions = {
        live_grep_args = {
            auto_quoting = true,
            -- VS Code-style refinement: type rg flags inline after `--`.
            -- Examples (typed into the prompt):
            --   foo -- -t lua          (only Lua files)
            --   foo -- -s              (case-sensitive)
            --   foo -- -w              (whole word)
            --   foo -- -F              (fixed string, no regex)
            --   foo -- -g '*.test.*'   (glob filter)
            mappings = {
                i = {
                    ["<C-k>"] = require("telescope-live-grep-args.actions").quote_prompt(),
                    ["<C-i>"] = require("telescope-live-grep-args.actions").quote_prompt({ postfix = " --iglob " }),
                },
            },
        },
    },
})

telescope.load_extension("live_grep_args")

-- Existing project-find shortcuts
vim.keymap.set("n", "<leader>pf", builtin.find_files,                       { desc = "Find files" })
vim.keymap.set("n", "<C-p>",      builtin.git_files,                        { desc = "Find git files" })
vim.keymap.set("n", "<leader>ps", function() lga.grep_word_under_cursor() end, { desc = "Grep word under cursor" })

-- VS Code-style search:
--   <leader>f   fuzzy-find within current file
--   <leader>F   grep across the project (refinable a la VS Code)
local function find_in_file()
    builtin.current_buffer_fuzzy_find({
        case_mode = "ignore_case",
        previewer = false,
    })
end

local function find_in_all_files()
    telescope.extensions.live_grep_args.live_grep_args()
end

vim.keymap.set("n", "<leader>f", find_in_file,      { desc = "Find in current file" })
vim.keymap.set("n", "<leader>F", find_in_all_files, { desc = "Find in all files" })

-- Find files by glob/wildcard pattern (e.g., *.lua, src/**/*.ts, **/test_*.py).
-- Uses ripgrep so .gitignore is respected. Empty input = list everything.
vim.keymap.set("n", "<leader>p", function()
    vim.ui.input({ prompt = "Find files matching glob: ", default = "*" }, function(glob)
        if not glob or glob == "" then return end
        builtin.find_files({
            prompt_title = "Find Files (glob: " .. glob .. ")",
            find_command = { "rg", "--files", "--hidden", "--glob", glob, "--glob", "!.git" },
        })
    end)
end, { desc = "Find files by glob pattern" })

