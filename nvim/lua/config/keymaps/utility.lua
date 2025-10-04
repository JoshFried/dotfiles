return {
    { "n", "Q", "<nop>", { desc = "Disable Ex mode" } },
    { "n", "dd", function()
        if vim.fn.getline(".") == "" then return '"_dd' end
        return "dd"
    end, { expr = true, desc = "Smart delete line" } },
    { "n", "<leader>dm", ":delm! | delm A-Z0-9<CR>", { desc = "Delete all marks" } },
    { "n", "<leader>a", "<cmd>AmazonQ toggle<CR>", { desc = "Toggle Amazon Q" } },
}
