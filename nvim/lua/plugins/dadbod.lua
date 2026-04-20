return {
    {
        "tpope/vim-dadbod",
        dependencies = {
            "kristijanhusak/vim-dadbod-ui",
            "kristijanhusak/vim-dadbod-completion",
        },
        config = function()
            vim.g.db_ui_save_location = vim.fn.stdpath("config") .. require("plenary.path").path.sep .. "db_ui"

            -- blink.cmp picks up omnifunc via its `omni` source (see blink.lua per_filetype).
            vim.api.nvim_create_autocmd("FileType", {
                pattern = { "sql", "mysql", "plsql" },
                command = [[setlocal omnifunc=vim_dadbod_completion#omni]],
            })
        end,
        keys = {
            { "<leader>Dt", "<cmd>DBUIToggle<cr>",        desc = "Toggle UI" },
            { "<leader>Df", "<cmd>DBUIFindBuffer<cr>",    desc = "Find Buffer" },
            { "<leader>Dr", "<cmd>DBUIRenameBuffer<cr>",  desc = "Rename Buffer" },
            { "<leader>Dq", "<cmd>DBUILastQueryInfo<cr>", desc = "Last Query Info" },
        },
    },
}
