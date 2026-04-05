local M = {
    "nvim-treesitter/nvim-treesitter",
    opts = function()
        require("nvim-treesitter").install({ "rust" })
    end,
}

return M
