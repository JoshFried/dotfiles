local M = {
    "saecki/Crates.nvim",
    event = { "BufRead Cargo.toml" },
    null_ls = {
        enabled = true,
        name = "crates.nvim",
    },
    dependencies = { "nvim-lua/plenary.nvim" },
}

M.config = function()
    require("crates").setup({
        src = {
            cmp = {
                enabled = true
            },
        },
        null_ls = {
            enabled = true,
            name = "crates.nvim",
        },
        popup = {
            border = "rounded",
        },
    })
end


return M
