local M = {
    {
        "sindrets/diffview.nvim",
        cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFocusFiles" },
        config = true,
    },
    {
        "TimUntersberger/neogit",
        cmd = "Neogit",
        opts = {
            integrations = { diffview = true },
        },
        keys = {
            { "<leader>gs", "<cmd>Neogit kind=tab<cr>", desc = "Status" },
        },
    },
    {
        "tpope/vim-fugitive",
        cmd = { "Git", "GBrowse", "Gdiffsplit", "Gvdiffsplit" },
        dependencies = {
            "tpope/vim-rhubarb",
        },
    },
    {
        "f-person/git-blame.nvim",
        event = "VeryLazy",
    }
}


return M
