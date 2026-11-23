-- Load the coverage viewer through :Coverage to display coverage data inside the
-- editor.

local M = {
    "andythigpen/nvim-coverage",
    cmd = { "Coverage" },
    config = function()
        require("coverage").setup()
    end,
}

return M
