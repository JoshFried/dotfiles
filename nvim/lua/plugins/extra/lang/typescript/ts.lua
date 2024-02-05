local M = {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
        vim.list_extend(opts.ensure_installed, { "javascript", "typescript", "tsx", "prisma" })
    end,
}


return M
