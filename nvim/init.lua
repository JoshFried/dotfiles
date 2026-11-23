-- Neovim entry point. Set options and apply compatibility patches before plugin
-- setup. Global keymaps load on VeryLazy so their plugin commands are available when
-- used.

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
