-- Install JavaScript, TypeScript, TSX and Prisma parsers through Tree-sitter.

local M = {
    "nvim-treesitter/nvim-treesitter",
    opts = function()
        require("nvim-treesitter").install({ "javascript", "typescript", "tsx", "prisma" })
    end,
}

return M
