return {
	-- real nice way to navigate common files that i hop between but seem to use telescope more tbh
	{
		"ThePrimeagen/harpoon",
		keys = {
			{
				"<leader>af",
				function()
					require("harpoon.mark").add_file()
				end,
				desc = "Add File",
			},
			{
				"<leader>ff",
				function()
					require("harpoon.ui").toggle_quick_menu()
				end,
				desc = "File Menu",
			},
			{
				"<leader>gf1",
				function()
					require("harpoon.ui").nav_file(1)
				end,
				desc = "Go To File 1",
			},
			{
				"<leader>gf2",
				function()
					require("harpoon.ui").nav_file(2)
				end,
				desc = "Go To File 2",
			},
			{
				"<leader>gf3",
				function()
					require("harpoon.ui").nav_file(3)
				end,
				desc = "Go To File 3",
			},
			{
				"<leader>gf4",
				function()
					require("harpoon.ui").nav_file(4)
				end,
				desc = "Go To File 4",
			},
			{
				"<leader>gf5",
				function()
					require("harpoon.ui").nav_file(5)
				end,
				desc = "Go To File 5",
			},
		},
		opts = {
			global_settings = {
				save_on_toggle = true,
				enter_on_sendcmd = true,
			},
		},
	},
}
