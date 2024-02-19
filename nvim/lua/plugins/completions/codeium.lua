local M = {
    {
        "Exafunction/codeium.nvim",
        cmd          = "Codeium",
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
        config       = function()
            require("codeium").setup({})
        end
    },
}

local home_path = os.getenv("HOME")
--
--
-- doing this so we dont use this at work :)
if home_path == "/Users/joshfried" then
    return M
end

return {}
