--- Install lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)


-- Configure lazy.nvim
require("lazy").setup({
    spec = {
        { import = "plugins" },
        { import = "plugins.extra.lang" },
        { import = "plugins.extra.pde" },
        { import = "plugins.test" },
        { import = "plugins.lsp.init" },
        { import = "plugins.lsp.work" },
    },
    defaults = { lazy = true, version = nil },
    install = { colorscheme = { "kanagawa-wave" } },
    checker = { enabled = true },
})

vim.keymap.set("n", "<leader>z", "<cmd>:Lazy<cr>", { desc = "Plugin Manager" })
