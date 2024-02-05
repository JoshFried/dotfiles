local M = {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
        vim.list_extend(opts.ensure_installed, { "ninja", "python", "rst", "toml" })
    end,
}

return M
