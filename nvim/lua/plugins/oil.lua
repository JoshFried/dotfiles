return {
    {
        'stevearc/oil.nvim',
        event = "VeryLazy",
        opts = {},
        -- Optional dependencies
        dependencies = { "nvim-tree/nvim-web-devicons" },
        keys = {
            { "n", "-", "<cmd>Oil<cr>", { desc = "Open parent directory" } },
        }
    }
}
