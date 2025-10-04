return {
    -- Move lines
    { "n", "<A-j>", ":m .+1<CR>==", { desc = "Move line down" } },
    { "v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" } },
    { "i", "<A-j>", "<Esc>:m .+1<CR>==gi", { desc = "Move line down" } },
    { "n", "<A-k>", ":m .-2<CR>==", { desc = "Move line up" } },
    { "v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" } },
    { "i", "<A-k>", "<Esc>:m .-2<CR>==gi", { desc = "Move line up" } },
    
    -- Undo break-points
    { "i", ",", ",<c-g>u", { desc = "Undo break point" } },
    { "i", ".", ".<c-g>u", { desc = "Undo break point" } },
    { "i", ";", ";<c-g>u", { desc = "Undo break point" } },
    
    -- Visual mode
    { "v", "<", "<gv", { desc = "Indent left" } },
    { "v", ">", ">gv", { desc = "Indent right" } },
}
