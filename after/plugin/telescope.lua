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

-- Find files by glob/wildcard, live-updating like <leader>F.
-- Type *.lua, src/**/*.ts, **/test_*.py, etc. and results update on each keystroke.
vim.keymap.set("n", "<leader>p", function()
    local finders   = require("telescope.finders")
    local pickers   = require("telescope.pickers")
    local conf      = require("telescope.config").values
    local make_entry = require("telescope.make_entry")

    pickers.new({}, {
        prompt_title = "Find Files (glob)",
        finder = finders.new_job(function(prompt)
            if not prompt or prompt == "" then return nil end
            -- If the user didn't include any glob metacharacters, treat the
            -- input as a substring by wrapping it in *...*. So "foo" becomes
            -- "*foo*", but "*.lua" / "src/**/*.ts" pass through unchanged.
            if not prompt:find("[%*%?%[%]{}]") then
                prompt = "*" .. prompt .. "*"
            end
            return { "rg", "--files", "--hidden", "--iglob", prompt, "--glob", "!.git" }
        end, make_entry.gen_from_file({}), nil, nil),
        previewer = conf.file_previewer({}),
        sorter = conf.file_sorter({}),
    }):find()
end, { desc = "Find files by glob (live)" })

