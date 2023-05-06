return {
	{
		"mrjones2014/legendary.nvim",
		keys = {
			{ "<C-S-p>", "<cmd>Legendary<cr>", desc = "Legendary" },
			{ "<leader>hc", "<cmd>Legendary<cr>", desc = "Command Palette" },
		},
		opts = {
			which_key = { auto_register = true },
		},
	},
	{
		"folke/which-key.nvim",
		dependencies = {
			"mrjones2014/legendary.nvim",
		},
		event = "VeryLazy",
		opts = {},
		-- config = function()
		--  TODO: we gotta do something nice like this
		-- local wk = require("which-key")
		-- wk.setup({
		-- 	show_help = true,
		-- 	plugins = { spelling = true },
		-- 	key_labels = { ["<leader>"] = "SPC" },
		-- 	triggers = "auto",
		-- })
		-- end,
	},
}
