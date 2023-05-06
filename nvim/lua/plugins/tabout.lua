-- love this plugin when in insert mode and inside of brackets and stuff, pressing tab will make you go to the first whitespace outside of this bracket
return {
	"abecodes/tabout.nvim",
	event = "VeryLazy",
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"hrsh7th/nvim-cmp",
	},
	config = function()
		require("tabout").setup({
			tabouts = {
				{ open = "'", close = "'" },
				{ open = '"', close = '"' },
				{ open = "`", close = "`" },
				{ open = "(", close = ")" },
				{ open = "[", close = "]" },
				{ open = "{", close = "}" },
				{ open = "<", close = ">" },
			},
		})
	end,
}
