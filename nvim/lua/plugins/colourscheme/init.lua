return {
	{
		"folke/styler.nvim",
		event = "VeryLazy",
		config = function()
			require("styler").setup({
				themes = {
					markdown = { colorscheme = "kanagawa" },
					help = { colorscheme = "kanagawa" },
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
		end,
	},
	{
		"rebelot/kanagawa.nvim",
		name = "kanagawa",
		lazy = false,
		enable = true,
		priority = 1000,
		build = "KanagawaCompile",
		config = function()
			local theme = require("kanagawa")
			theme.setup({
				compile = true,
				transparent = true,
				commentStyle = { italic = false },
				keywordStyle = { italic = false },
				terminalColors = true,

				overrides = function(colors)
					local colours = colors.theme
					return {
						FloatBoarder = { bg = "none" },
						FloatTitle = { bg = "none" },
						NormalFloat = { bg = "none" },

						LazyNormal = { fg = colours.ui.fg_dim, bg = colours.ui.bg_m3 },
						MasonNormal = { fg = colours.ui.fg_dim, bg = colours.ui.bg_m3 },

						TelescopeTitle = { fg = colours.ui.special, bold = true },
						TelescopePromptNormal = { bg = colours.ui.bg_p1 },
						TelescopePromptBorder = { bg = colours.ui.bg_p1, fg = colours.ui.bg_p1 },
						TelescopeResultsNormal = { bg = colours.ui.bg_m1, fg = colours.ui.fg_dim },
						TelescopeResultsBorder = { bg = colours.ui.bg_m1, fg = colours.ui.bg_m1 },
						TelescopePreviewNormal = { bg = colours.ui.db_dim },
						TelescopePreviewBorder = { bg = colours.ui.bg_dim, fg = colours.ui.bg_dim },

						Pmenue = { fb = colours.ui.shade0, bg = colours.ui.bg_p1 },
						PmenuSel = { fg = "none", bg = colours.ui.bg_p2 },
						PmenuSbar = { bg = colours.ui.bg_m1 },
						PmenuThumb = { bg = colours.ui.bg_p2 },

						LspInlayHint = { bg = "none", fg = "7f7f7f" },
					}
				end,
			})

			vim.cmd.colorscheme("kanagawa")

			-- NOTE: not sure why this is the only way i can get a transparent background while keeping the overrides and compiles arg here....but im fed up of playing around
			local highlights = {
				"Normal",
				"LineNr",
				"Folded",
				"NonText",
				"SpecialKey",
				"VertSplit",
				"SignColumn",
				"EndOfBuffer",
				"TablineFill", -- this is specific to how I like my tabline to look like
			}
			for _, name in pairs(highlights) do
				vim.cmd.highlight(name .. " guibg=none ctermbg=none")
			end
		end,
	},
}
