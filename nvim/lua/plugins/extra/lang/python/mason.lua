local M = {
    "williamboman/mason.nvim",
    opts = function(_, opts)
        vim.list_extend(opts.ensure_installed, { "debugpy", "black", "ruff" })
    end,
}

return M
