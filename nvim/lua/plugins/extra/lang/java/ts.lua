local M = {
    "nvim-treesitter/nvim-treesitter",
    opts = function()
        require("nvim-treesitter").install({ "java", "kotlin" })
    end,
}

return M
