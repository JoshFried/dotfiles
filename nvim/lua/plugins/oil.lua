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

            -- When renaming/moving files in oil, notify LSP to update imports
            vim.api.nvim_create_autocmd("User", {
                pattern = "OilActionsPost",
                callback = function(event)
                    if event.data.actions[1].type == "move" then
                        require("snacks").rename.on_rename_file(event.data.actions[1].src_url, event.data.actions[1].dest_url)
                    end
                end,
            })

            vim.keymap.set("n", "<leader>-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
            vim.keymap.set("n", "<leader>+", function() oil.toggle_float() end,
                { desc = "Open parent directory float" })
        end
    }
}
