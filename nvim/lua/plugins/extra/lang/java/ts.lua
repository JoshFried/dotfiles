-- Install Java and Kotlin parsers through the shared Tree-sitter plugin.

local M = {
    "nvim-treesitter/nvim-treesitter",
    opts = function()
        require("nvim-treesitter").install({ "java", "kotlin" })
    end,
}

return M
