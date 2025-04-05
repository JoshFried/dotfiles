local M = {
    'Exafunction/codeium.nvim',
    enabled = true,
    lazy = false,
    dependencies = {
        "nvim-lua/plenary.nvim",
        "hrsh7th/nvim-cmp",
    },
    config = function()
        -- require("codeium").setup({
        -- })
    end
}

local home_path = os.getenv("HOME")
--
--
-- doing this so we dont use this at work :)
if home_path == "/Users/joshfried" then
    return M
end

return M
