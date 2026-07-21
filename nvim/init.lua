require("config.options")
require("config.patches")
require("config.autocmds")
require("config.lazy")


vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    callback = function()
        require("config.keymaps")
    end,
})
