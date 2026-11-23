-- Load Mkdnflow for Markdown buffers. Its options and mappings control link and
-- document navigation.

return {
	{
		"jakewvincent/mkdnflow.nvim",
		ft = { "markdown" },
		rocks = "luautf8",
		opts = {},
		enabled = false,
	},
	{ "AckslD/nvim-FeMaco.lua", ft = { "markdown" }, opts = {} },
	{
		"iamcco/markdown-preview.nvim",
		ft = { "markdown" },
		build = "cd app && npm install && git checkout .",
		init = function()
			vim.g.mkdp_filetypes = { "markdown" }
		end,
	},
}
