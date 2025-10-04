return {
    {
        'stevearc/oil.nvim',
        event = "VeryLazy",
        opts = {},
        -- Optional dependencies
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            local ok, oil = pcall(require, "oil")
            if not ok then 
                vim.notify("Failed to load oil.nvim", vim.log.levels.ERROR)
                return 
            end
            
            oil.setup()

            vim.keymap.set("n", "<leader>-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
            vim.keymap.set("n", "<leader>+", function() oil.toggle_float() end,
                { desc = "Open parent directory float" })
        end
    }
}
