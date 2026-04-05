local M = {
    "nvimtools/none-ls.nvim",
    opts = function(_, opts)
        local nls = require("null-ls")
        opts.sources = opts.sources or {}

        vim.list_extend(opts.sources, {
            -- Prettierd will automatically find your prettier.config.mjs or .prettierrc
            nls.builtins.formatting.prettierd,
        })
        return opts
    end,
}

return M
