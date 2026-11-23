-- Seed a whole-word substitution from the word under the cursor and leave the
-- replacement editable on the command line.

return {
    { "n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = "Search and replace word" } },
}
