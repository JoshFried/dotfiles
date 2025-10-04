local M = {
    "vim-test/vim-test",
    keys = {
        { "<leader>tc", "<cmd>w|TestClass<cr>",   desc = "Class" },
        { "<leader>tf", "<cmd>w|TestFile<cr>",    desc = "File" },
        { "<leader>tl", "<cmd>w|TestLast<cr>",    desc = "Last" },
        { "<leader>tn", "<cmd>w|TestNearest<cr>", desc = "Nearest" },
        { "<leader>ts", "<cmd>w|TestSuite<cr>",   desc = "Suite" },
        { "<leader>tv", "<cmd>w|TestVisit<cr>",   desc = "Visit" },
    },
}


M.config = function()
    vim.g["test#strategy"] = "neovim"
    vim.g["test#neovim#term_position"] = "belowright"
    vim.g["test#neovim#preserve_screen"] = 1

    vim.g["test#python#runner"] = "pyunit" -- pytest
end

return M
