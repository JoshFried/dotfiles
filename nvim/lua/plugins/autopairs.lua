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

            local cmp_ok, cmp = pcall(require, "cmp")
            if cmp_ok then
                cmp.event:on("confirm_done", require("nvim-autopairs.completion.cmp").on_confirm_done())
            end
        end,
    },
}
