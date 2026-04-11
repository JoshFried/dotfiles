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
		-- Work-only plugins. Directory is gitignored so it only exists on work machines.
		-- so it only exists on work machines. optional=true prevents errors when missing.
		vim.uv.fs_stat(vim.fn.stdpath("config") .. "lua/plugins/work") and { import = "plugins.work", optional = true }
			or {},
	},
	defaults = { lazy = true, version = nil },
	install = { colorscheme = { "kanagawa-wave" } },
	checker = { enabled = true },
})

vim.keymap.set("n", "<leader>z", "<cmd>:Lazy<cr>", { desc = "Plugin Manager" })
