local M = {
    "williamboman/mason.nvim",
    opts = function(_, opts)
        vim.list_extend(opts.ensure_installed,
            { "jdtls", "google-java-format", "checkstyle", "kotlin-lsp", "detekt", "ktfmt" })
        -- vim.list_extend(opts.ensure_installed, { "google-java-format", "checkstyle" })
    end,
}

return M
