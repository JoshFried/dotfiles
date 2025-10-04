return {
    -- Line manipulation
    { "n", "zj", "o<Esc>k", { desc = "Create line above without insert" } },
    { "n", "zk", "O<Esc>j", { desc = "Create line below without insert" } },
    { "n", "J", "mzJ`z", { desc = "Join lines" } },
    
    -- Movement
    { "n", "<C-d>", "<C-d>zz", { desc = "Half page down centered" } },
    { "n", "<C-u>", "<C-u>zz", { desc = "Half page up centered" } },
    { "n", "n", "nzzzv", { desc = "Next search centered" } },
    { "n", "N", "Nzzzv", { desc = "Previous search centered" } },
    { { "n", "o", "x" }, "<s-h>", "^", { desc = "Start of line" } },
    { { "n", "o", "x" }, "<s-l>", "g_", { desc = "End of line" } },
    { "n", "<BS>", "^", { desc = "Move to first non-blank char" } },
    
    -- Text objects
    { "n", "<CR>", "ciw", { desc = "Change inner word" } },
    { "n", "<leader>L", "vg_", { desc = "Select to end of line" } },
    { "n", "<leader>sa", "ggVG", { desc = "Select all" } },
    { "n", "<leader>pa", "ggVGp", { desc = "Select all and paste" } },
    { "n", "<leader>gp", "`[v`]", { desc = "Select pasted text" } },
    
    -- Undo/Redo
    { "n", "U", "<C-r>", { desc = "Redo" } },
    { "i", "jj", "<esc>", { desc = "Exit insert mode" } },
    { "i", "kk", "<esc>", { desc = "Exit insert mode" } },
}
