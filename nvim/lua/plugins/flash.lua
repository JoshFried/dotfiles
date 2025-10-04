return {
	{
		"folke/flash.nvim",
		event = "VeryLazy",
		keys = {
			{ "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
			{ "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
			{ "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
			{ "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
			{ "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
		},
		opts = {
			modes = {
				char = {
					enabled = true,
					keys = { "f", "F", "t", "T" },
				},
			},
		},
		config = function(_, opts)
			local ok, flash = pcall(require, "flash")
			if not ok then 
				vim.notify("Failed to load flash.nvim", vim.log.levels.ERROR)
				return 
			end
			flash.setup(opts)
		end,
	},
}
