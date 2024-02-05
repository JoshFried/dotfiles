local M = {
    "williamboman/mason.nvim",
    opts = function(_, opts)
        vim.list_extend(opts.ensure_installed, { "typescript-language-server", "js-debug-adapter" })
    end,
}

return M
