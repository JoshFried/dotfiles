return {
    { "n", "[d",         function() vim.diagnostic.jump({ count = -1 }) end, { desc = "Previous diagnostic" } },
    { "n", "]d",         function() vim.diagnostic.jump({ count = 1 }) end,  { desc = "Next diagnostic" } },
    { "n", "<leader>de", vim.diagnostic.open_float,          { desc = "Show diagnostic" } },
    { "n", "<leader>dl", vim.diagnostic.setloclist,          { desc = "Diagnostic list" } },
    { "n", "<leader>f",  vim.lsp.buf.format,                 { desc = "Format document" } },
}
