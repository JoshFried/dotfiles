local M = {
    "jose-elias-alvarez/null-ls.nvim",
    opts = function(_, opts)
        local nls = require "null-ls"
        table.insert(opts.sources, nls.builtins.formatting.black)
    end,
}

return M
