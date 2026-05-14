-- Mason: package manager for LSPs, formatters, linters
require("mason").setup()
require("mason-lspconfig").setup({
    ensure_installed = {
        -- Core
        "lua_ls",
        "rust_analyzer",
        -- Web / TS / JS
        "ts_ls",
        "eslint",
        "html",
        "cssls",
        "jsonls",
        -- .NET / Blazor / Razor / XAML / XML
        "omnisharp",     -- C# (.cs, .cshtml, .razor)
        "lemminx",       -- XML / XAML
        -- Config / infra
        "yamlls",
        "bicep",
        "powershell_es",
        -- Docs
        "marksman",      -- Markdown
    },
    -- mason-lspconfig v2 automatically calls vim.lsp.enable() for each
    -- installed server using configs shipped with nvim-lspconfig.
    automatic_enable = true,
})

-- nvim-cmp: completion engine
local cmp = require("cmp")
local cmp_select = { behavior = cmp.SelectBehavior.Select }

require("luasnip.loaders.from_vscode").lazy_load()

cmp.setup({
    snippet = {
        expand = function(args) require("luasnip").lsp_expand(args.body) end,
    },
    sources = cmp.config.sources({
        { name = "nvim_lsp" },
        { name = "nvim_lua" },
        { name = "luasnip" },
    }, {
        { name = "buffer" },
        { name = "path" },
    }),
    mapping = cmp.mapping.preset.insert({
        ["<C-p>"] = cmp.mapping.select_prev_item(cmp_select),
        ["<C-n>"] = cmp.mapping.select_next_item(cmp_select),
        ["<C-y>"] = cmp.mapping.confirm({ select = true }),
        ["<C-Space>"] = cmp.mapping.complete(),
    }),
})

-- Global LSP defaults: advertise cmp's completion capabilities to every server
vim.lsp.config("*", {
    capabilities = require("cmp_nvim_lsp").default_capabilities(),
})

-- Per-server overrides
vim.lsp.config("lua_ls", {
    settings = {
        Lua = {
            diagnostics = { globals = { "vim" } },
        },
    },
})

-- Diagnostics UI
vim.diagnostic.config({
    virtual_text = true,
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = "E",
            [vim.diagnostic.severity.WARN]  = "W",
            [vim.diagnostic.severity.HINT]  = "H",
            [vim.diagnostic.severity.INFO]  = "I",
        },
    },
})

-- Keymaps + behavior on LSP attach (replaces lsp-zero.on_attach)
vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("davidkavanaugh-lsp-attach", { clear = true }),
    callback = function(args)
        local bufnr = args.buf
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if not client then return end

        -- ESLint client: disable; we use it only for formatting via cmd
        if client.name == "eslint" then
            vim.lsp.stop_client(client.id)
            return
        end

        local opts = { buffer = bufnr, remap = false }
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
        vim.keymap.set("n", "<leader>vws", vim.lsp.buf.workspace_symbol, opts)
        vim.keymap.set("n", "<leader>vd", vim.diagnostic.open_float, opts)
        vim.keymap.set("n", "[d", function() vim.diagnostic.jump({ count = 1, float = true }) end, opts)
        vim.keymap.set("n", "]d", function() vim.diagnostic.jump({ count = -1, float = true }) end, opts)
        vim.keymap.set("n", "<leader>vca", vim.lsp.buf.code_action, opts)
        vim.keymap.set("n", "<leader>vrr", vim.lsp.buf.references, opts)
        vim.keymap.set("n", "<leader>vrn", vim.lsp.buf.rename, opts)
        vim.keymap.set("i", "<C-h>", vim.lsp.buf.signature_help, opts)

        -- Trouble.nvim
        vim.keymap.set("n", "<leader>xx", "<cmd>TroubleToggle<cr>", opts)
        vim.keymap.set("n", "<leader>xw", "<cmd>TroubleToggle workspace_diagnostics<cr>", opts)
        vim.keymap.set("n", "<leader>xd", "<cmd>TroubleToggle document_diagnostics<cr>", opts)
        vim.keymap.set("n", "<leader>xl", "<cmd>TroubleToggle loclist<cr>", opts)
        vim.keymap.set("n", "<leader>xq", "<cmd>TroubleToggle quickfix<cr>", opts)
        vim.keymap.set("n", "gR", "<cmd>TroubleToggle lsp_references<cr>", opts)
    end,
})

require("trouble").setup({
    icons = false,
    auto_preview = false,
    signs = {
        error = "E",
        warning = "W",
        hint = "H",
        information = "I",
    },
})
