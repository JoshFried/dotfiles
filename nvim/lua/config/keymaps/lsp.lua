return {
    { "n", "[d",         vim.diagnostic.goto_prev,           { desc = "Previous diagnostic" } },
    { "n", "]d",         vim.diagnostic.goto_next,           { desc = "Next diagnostic" } },
    { "n", "<leader>de", vim.diagnostic.open_float,          { desc = "Show diagnostic" } },
    { "n", "<leader>dl", vim.diagnostic.setloclist,          { desc = "Diagnostic list" } },
    { "n", "<leader>f",  vim.lsp.buf.format,                 { desc = "Format document" } },
}
