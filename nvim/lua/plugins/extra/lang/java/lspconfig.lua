local M = {
    "neovim/nvim-lspconfig",
    dependencies = { "pmizio/typescript-tools.nvim" },
    opts = {
        -- make sure mason installs the server
        servers = {
            kotlin_lsp = {}
        },
        setup = {
            kotlin_lsp = function()
                vim.lsp.enable("kotlin_lsp")
            end
        }
    },
}

return M
