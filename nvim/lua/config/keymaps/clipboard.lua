return {
    { "x", "<leader>p", [["_dP]], { desc = "Paste without overwrite" } },
    { { "n", "v" }, "<leader>y", [["+y]], { desc = "Yank to system clipboard" } },
    { "n", "<leader>Y", [["+Y]], { desc = "Yank line to system clipboard" } },
    { { "n", "v" }, "<leader>d", [["_d]], { desc = "Delete without overwrite" } },
    { "n", "<leader>yf", ":%y<cr>", { desc = "Yank entire file" } },
    { "n", "<leader>rl", function() require("telescope.builtin").registers() end, { desc = "Show registers" } },
}
