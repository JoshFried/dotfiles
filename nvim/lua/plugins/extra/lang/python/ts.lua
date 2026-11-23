-- Request parsers used by Python projects, including Python, reStructuredText, TOML
-- and Ninja.

local M = {
    "nvim-treesitter/nvim-treesitter",
    opts = function()
        require("nvim-treesitter").install({ "ninja", "python", "rst", "toml" })
    end,
}

return M
