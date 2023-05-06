return {
	{
		"folke/todo-comments.nvim",
		cmd = { "TodoTrouble", "TodoTelescope" },
		event = "BufReadPost",
		config = true,
		keys = {
			{
				"]t",
				function()
					require("todo-comments").jump_next()
				end,
				desc = "Next ToDo",
			},
			{
				"[t",
				function()
					require("todo-comments").jump_prev()
				end,
				desc = "Previous ToDo",
			},
			-- one of the nicest quality of life plugins here....use telescope to show all todo's in a project :)
			{ "<leader>ct", "<cmd>TodoTelescope<cr>", desc = "ToDo" },
		},
	},
}
