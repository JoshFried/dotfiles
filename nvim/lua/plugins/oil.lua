return {
    {
        'stevearc/oil.nvim',
        event = "VeryLazy",
        opts = {},
        -- Optional dependencies
        -- dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require("oil").setup()

            vim.keymap.set("n", "<leader>-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
            vim.keymap.set("n", "<leader>+", function() require("oil").toggle_float() end,
                { desc = "Open parent directory float" })
        end
    }
}
