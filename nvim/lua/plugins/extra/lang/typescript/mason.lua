return {
    "williamboman/mason.nvim",
    opts = function(_, opts)
        vim.list_extend(opts.ensure_installed, { "vtsls", "js-debug-adapter", "eslint-lsp", "prettierd" })
    end,
}
