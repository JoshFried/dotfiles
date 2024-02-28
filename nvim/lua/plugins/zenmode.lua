return {
    "folke/zen-mode.nvim",
    keys = {
        { "<leader>zz", [[<cmd>lua require("zen-mode").toggle()<cr>]], desc = "Zen mode" },
    },
    opts = {
        window = {
            width = 0.50,
            height = 0.85,
            options = {
                colorcolumn = "",
                cursorcolumn = false,
                cursorline = false,
                number = true,
                relativenumber = true,
            },
        },
        plugins = {
            options = {
                laststatus = 3,
            },
            gitsigns = { enabled = true },
        }
    },
}
