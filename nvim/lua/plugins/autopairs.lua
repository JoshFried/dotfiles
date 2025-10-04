return {
    {
        "windwp/nvim-autopairs",
        event = "VeryLazy",
        config = function()
            local ok, autopairs = pcall(require, "nvim-autopairs")
            if not ok then 
                vim.notify("Failed to load nvim-autopairs", vim.log.levels.ERROR)
                return 
            end
            
            autopairs.setup({})
        end,
    },
}
