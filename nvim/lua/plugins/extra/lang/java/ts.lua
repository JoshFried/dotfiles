local M = {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
        vim.list_extend(opts.ensure_installed, { "java", "kotlin" })
    end,
}

return M
