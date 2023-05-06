return {
	{
		"folke/styler.nvim",
		event = "VeryLazy",
		config = function()
			require("styler").setup({
				themes = {
					markdown = { colorscheme = "tokyonight" },
					help = { colorscheme = "tokyonight" },
				},
			})
		end,
	},
	{
		"folke/tokyonight.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			local tokyonight = require("tokyonight")
			tokyonight.setup({
				style = "storm",
				transparent = true,
				styles = {
					comments = { italic = false },
					keywords = { italic = false },
				},
			})
			vim.cmd.colorscheme("tokyonight")
		end,
	},
	{
		"ellisonleao/gruvbox.nvim",
		lazy = false,
		config = function()
			require("gruvbox").setup()
		end,
	},

	{
		lazy = true,
		"rmehri01/onenord.nvim",
		config = function()
			local onenord = require("onenord")
			onenord.setup({
				priority = 1000,
				disable = {
					background = true,
				},
			})
		end,
	},
	{
		"catppuccin/nvim",
		name = "catppuccin",
		lazy = false,
		config = function()
			local theme = require("catppuccin")
			theme.setup({
				flavour = "mocha",
				transparent_background = true,
				no_italic = true,
			})
			-- theme.load()
		end,
	},
}
