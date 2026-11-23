-- Request vtsls, the JavaScript debug adapter, ESLint's server and prettierd through
-- Mason.

return {
    "williamboman/mason.nvim",
    opts = function(_, opts)
        vim.list_extend(opts.ensure_installed, { "vtsls", "js-debug-adapter", "eslint-lsp", "prettierd" })
    end,
}
