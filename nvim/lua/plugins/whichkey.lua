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
		opts = {
			spec = {
				{ "<leader>s", group = "search" },
				{ "<leader>f", group = "file" },
				{ "<leader>g", group = "git" },
				{ "<leader>b", group = "brazil" },
				{ "<leader>d", group = "diagnostics" },
				{ "<leader>t", group = "telescope" },
				{ "<leader>p", group = "project" },
				{ "<leader>y", group = "yank" },
				{ "<leader>x", group = "file-path" },
				{ "<leader>a", group = "amazon-q" },
			},
		},
	},
}
