local bufnr = vim.api.nvim_get_current_buf()
vim.keymap.set(
    "n",
    "<leader>a",
    function()
        vim.cmd.RustLsp('codeAction') -- supports rust-analyzer's grouping
        -- or vim.lsp.buf.codeAction() if you don't want grouping.
    end,
    { silent = true, buffer = bufnr }
)

vim.keymap.set(
    "n",
    "<leader>Rd",
    "<cmd>RustLsp debuggables<CR>",
    { buffer = bufnr, desc = "Debuggables" }
)
vim.keymap.set(
    "n",
    "<leader>ha",
    "<cmd>RustLsp hoverActions<CR>",
    { buffer = bufnr, desc = "Hover Actions" }
)
vim.keymap.set(
    "n",
    "<leader>roc",
    "<cmd>RustLsp openCargo<CR>",
    { buffer = bufnr, desc = "Open Cargo" }
)
vim.keymap.set(
    "n",
    "<leader>rpm",
    "<cmd>RustLsp parentModule<CR>",
    { buffer = bufnr, desc = "Parent Module" }
)
vim.keymap.set("n", "<leader>cl", function()
    vim.lsp.codelens.run()
end, { buffer = bufnr, desc = "Code Lens" })
