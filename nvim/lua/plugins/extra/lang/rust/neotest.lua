-- Register rustaceanvim's test adapter with Neotest so Rust tests appear in the
-- shared test interface.

local M = {
    "nvim-neotest/neotest",
    opts = function(_, opts)
        vim.list_extend(opts.adapters, {
            require('rustaceanvim.neotest')
        })
    end,
}

return M
