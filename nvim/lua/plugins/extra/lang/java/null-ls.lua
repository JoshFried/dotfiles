local M = {
    "nvimtools/none-ls.nvim",
    opts = function(_, opts)
        local nls = require "null-ls"
        table.insert(opts.sources, nls.builtins.formatting.google_java_format.with({
            extra_args = {
                "--aosp"
            }
        }))
        table.insert(opts.sources, nls.builtins.diagnostics.checkstyle.with({
            extra_args = {
                "-c", "./checkstyle.xml"
            }
        }))
    end,
}

return M
