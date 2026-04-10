return {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    cmd = { "ConformInfo" },
    keys = {
        { "<leader>cF", function() require("conform").format({ async = true }) end, desc = "Format (conform)" },
    },
    opts = {
        formatters_by_ft = {
            go = { "gofmt", "goimports_reviser" },
            java = { "google-java-format" },
            kotlin = { "ktlint" },
            python = { "black" },
            typescript = { "prettierd" },
            typescriptreact = { "prettierd" },
            javascript = { "prettierd" },
            javascriptreact = { "prettierd" },
            html = { "prettierd" },
            css = { "prettierd" },
            json = { "prettierd" },
            sh = { "shfmt" },
            lua = { "stylua" },
        },
        -- format_on_save respects the autoformat toggle from plugins.lsp.format
        format_on_save = function()
            local format = require("plugins.lsp.format")
            if not format.autoformat then return end
            return { timeout_ms = 3000, lsp_format = "fallback" }
        end,
    },
}
