local M = {
    "nvim-neotest/neotest",
    opts = function(_, opts)
        vim.list_extend(opts.adapters, {
            require('rustaceanvim.neotest')
        })
    end,
}

return M
