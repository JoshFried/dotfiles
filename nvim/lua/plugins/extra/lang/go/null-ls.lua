local M = {
    "jose-elias-alvarez/null-ls.nvim",
    opts = function(_, opts)
        local nls = require "null-ls"
        table.insert(opts.sources, nls.builtins.formatting.gofmt)
        table.insert(opts.sources, nls.builtins.formatting.goimports_reviser)
        table.insert(opts.sources, nls.builtins.diagnostics.golangci_lint)
    end,
}

return M
