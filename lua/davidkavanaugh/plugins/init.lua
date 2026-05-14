return {
    -- Telescope
    {
        "nvim-telescope/telescope.nvim",
        tag = "0.1.0",
        dependencies = { "nvim-lua/plenary.nvim" },
    },

    -- Colorscheme
    { "rose-pine/neovim", name = "rose-pine", priority = 1000, lazy = false },

    -- Treesitter (pinned to legacy master branch; main branch dropped configs API)
    {
        "nvim-treesitter/nvim-treesitter",
        branch = "master",
        build = ":TSUpdate",
    },
    "nvim-treesitter/playground",

    -- Navigation / editing
    "theprimeagen/harpoon",
    "mbbill/undotree",
    "tpope/vim-fugitive",

    -- LSP + autocompletion (uses Neovim 0.11 native vim.lsp.config API)
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
            -- Autocompletion
            "hrsh7th/nvim-cmp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "saadparwaiz1/cmp_luasnip",
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-nvim-lua",
            -- Snippets
            "L3MON4D3/LuaSnip",
            "rafamadriz/friendly-snippets",
        },
    },

    "folke/zen-mode.nvim",
    "github/copilot.vim",
    "christoomey/vim-tmux-navigator",
    "tpope/vim-surround",
    {
        "windwp/nvim-autopairs",
        config = function() require("nvim-autopairs").setup({}) end,
    },
    "junegunn/vim-peekaboo",
    {
        "nvim-tree/nvim-tree.lua",
        dependencies = { "nvim-tree/nvim-web-devicons" },
    },
    "jose-elias-alvarez/typescript.nvim",
    "folke/trouble.nvim",
    "Djancyp/better-comments.nvim",

    -- Statusline
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
    },

    -- Git signs in the gutter
    "lewis6991/gitsigns.nvim",

    -- Keymap discovery popup
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
    },

    -- Copilot Chat (VS Code-style chat panel powered by Copilot)
    {
        "CopilotC-Nvim/CopilotChat.nvim",
        dependencies = {
            "github/copilot.vim",
            "nvim-lua/plenary.nvim",
        },
        cmd = { "CopilotChat", "CopilotChatToggle", "CopilotChatOpen" },
        keys = {
            { "<leader>cp", "<cmd>CopilotChatOpen<cr>",        mode = { "n", "v" }, desc = "Copilot chat open" },
            { "<leader>ce", "<cmd>CopilotChatExplain<cr>",     mode = { "n", "v" }, desc = "Copilot explain" },
            { "<leader>cr", "<cmd>CopilotChatReview<cr>",      mode = { "n", "v" }, desc = "Copilot review" },
            { "<leader>cf", "<cmd>CopilotChatFix<cr>",         mode = { "n", "v" }, desc = "Copilot fix" },
            { "<leader>co", "<cmd>CopilotChatOptimize<cr>",    mode = { "n", "v" }, desc = "Copilot optimize" },
            { "<leader>ct", "<cmd>CopilotChatTests<cr>",       mode = { "n", "v" }, desc = "Copilot generate tests" },
            { "<leader>cd", "<cmd>CopilotChatDocs<cr>",        mode = { "n", "v" }, desc = "Copilot generate docs" },
            { "<leader>cm", "<cmd>CopilotChatCommit<cr>",      mode = "n",          desc = "Copilot commit message" },
            { "<leader>cP", "<cmd>CopilotChatPrompts<cr>",     mode = { "n", "v" }, desc = "Copilot prompt picker" },
            { "<leader>cM", "<cmd>CopilotChatModels<cr>",      mode = "n",          desc = "Copilot model picker" },
        },
        opts = {
            model = "claude-opus-4",
            window = { layout = "vertical", width = 0.4 },
            mappings = {
                submit_prompt = { normal = "<CR>", insert = "<CR>" },
                close         = { normal = "<Esc>", insert = "" },
                reset         = { normal = "<C-r>", insert = "<C-r>" },
            },
        },
    },
}
