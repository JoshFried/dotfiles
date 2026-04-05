local M = {
    "nvim-treesitter/nvim-treesitter",
    opts = function()
        require("nvim-treesitter").install({ "javascript", "typescript", "tsx", "prisma" })
    end,
}

return M
