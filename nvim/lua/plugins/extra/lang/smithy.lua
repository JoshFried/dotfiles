return {
    {
        "nvim-treesitter/nvim-treesitter",
        opts = function(_, opts)
            vim.list_extend(opts.ensure_installed, { "smithy" })
        end,
    },
    {
        "williamboman/mason.nvim",
        opts = function(_, opts)
            vim.list_extend(opts.ensure_installed,
                { "smithy-language-server", })
        end,
    },
    {
        "neovim/nvim-lspconfig",
        ft = "smithy",
        config = function()
            vim.lsp.config.smithy_ls = {
                cmd = { 'smithy-language-server' },
                filetypes = { 'smithy' },
                root_markers = { 'smithy-build.json', '.git' },
            }
            vim.lsp.enable('smithy_ls')
        end,
    },
}
