local M = {
    "andythigpen/nvim-coverage",
    cmd = { "Coverage" },
    config = function()
        require("coverage").setup()
    end,
}

return M
