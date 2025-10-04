local utils = require('config.utils')

return {
    { "n", "<leader>pv", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle file tree" } },
    { "n", "<leader>cpf", ':let @+ = expand("%:p")<cr>:lua print("Copied path to: " .. vim.fn.expand("%:p"))<cr>', { desc = "Copy file path" } },
    { "n", "<leader>x", function() utils.CopyFilePathAndLineNumber() end, { desc = "Copy file path and line number" } },
    { "n", "<leader>xo", ":e <C-r>+<CR>", { desc = "Open file from clipboard" } },
}
