return {
    {
        "nvim-treesitter/nvim-treesitter",
        opts = function()
            require("nvim-treesitter").install({ "smithy" })
        end,
    },
    {
        "williamboman/mason.nvim",
        opts = function(_, opts)
            vim.list_extend(opts.ensure_installed,
                { "smithy-language-server", })
        end,
    },
    -- NOTE: no `config` here! nvim-lspconfig's config (plugins/lsp/servers.lua)
    -- is shared across all language fragments; defining `config` in a fragment
    -- REPLACES it (lazy.nvim last-wins) and silently kills every LSP server.
    -- smithy_ls is declared in plugins/lsp/init.lua base_servers, installed by
    -- the mason block above, and enabled via mason-lspconfig automatic_enable
    -- using nvim-lspconfig's shipped lsp/smithy_ls.lua defaults.
}
