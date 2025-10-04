return {
    "folke/twilight.nvim",
    event = "VeryLazy",
    opts = {
        context = 15, -- amount of lines we will try to show around the current line
    },
    keys = {
        { "<leader>zt", "<cmd>Twilight<CR>", desc = "harpoon file", },
    }
}
