local M = {
    "olexsmir/gopher.nvim",
    dependencies = {
        "leoluz/nvim-dap-go",
    },
    lazy = false,
}

M.config = function()
    local gopher = require("gopher")
    gopher.setup({
        commands = {
            go = "go",
            gomodifytags = "gomodifytags",
            gotests = "gotests",
            impl = "impl",
            iferr = "iferr",
        },
        goimport = "gopls",
        gofmt = "gopls",
    })
end

return M
