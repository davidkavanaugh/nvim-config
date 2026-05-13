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

    -- LSP stack (lsp-zero v1.x API; matches existing after/plugin/lsp.lua)
    {
        "VonHeikemen/lsp-zero.nvim",
        branch = "v1.x",
        dependencies = {
            -- LSP Support
            "neovim/nvim-lspconfig",
            { "williamboman/mason.nvim",            branch = "v1.x" },
            { "williamboman/mason-lspconfig.nvim",  branch = "v1.x" },
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
}
