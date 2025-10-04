local ok, utils = pcall(require, 'config.utils')
if not ok then
    vim.notify("Failed to load config.utils", vim.log.levels.ERROR)
    return {}
end

return {
    { "n", "<leader>sv", "<cmd>vsplit<CR><C-w>w", { desc = "Split vertically" } },
    { "n", "<leader>sh", "<cmd>split<CR><C-w>w", { desc = "Split horizontally" } },
    { "n", "<leader>0", function() utils.EqualizeSplits() end, { desc = "Equalize splits" } },
    
    -- Resize
    { "n", "<S-Up>", "<cmd>resize +2<CR>", { desc = "Resize up" } },
    { "n", "<S-Down>", "<cmd>resize -2<CR>", { desc = "Resize down" } },
    { "n", "<S-Left>", "<cmd>vertical resize -2<CR>", { desc = "Resize left" } },
    { "n", "<S-Right>", "<cmd>vertical resize +2<CR>", { desc = "Resize right" } },
}
