return {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufNewFile", "BufWritePost" },
    config = function()
        local lint = require("lint")
        lint.linters_by_ft = {
            go = { "golangcilint" },
            kotlin = { "ktlint" },
        }

        -- Only use checkstyle when config exists
        local checkstyle_config = vim.fn.findfile("checkstyle.xml", ".;")
        if checkstyle_config ~= "" then
            lint.linters_by_ft.java = { "checkstyle" }
        end

        vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost" }, {
            callback = function()
                lint.try_lint()
            end,
        })
    end,
}
