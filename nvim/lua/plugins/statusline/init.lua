return {
	{
		"nvim-lualine/lualine.nvim",
		event = "VeryLazy",

		config = function()
			local components = require("plugins.statusline.components")

			require("lualine").setup({
				options = {
					icons_enabled = true,
					theme = "auto",
					component_separators = {},
					section_separators = {},
					disabled_filetypes = {
						statusline = { "alpha", "lazy" },
						winbar = {
							"help",
							"alpha",
							"lazy",
						},
					},
					always_divide_middle = true,
					globalstatus = true,
				},
				sections = {
					lualine_a = { "mode" },
					lualine_b = { components.git_repo, "branch" },

					lualine_c = {
						components.diagnostics,
						"filename",
					},
					lualine_x = {
						components.lsp_client,
						components.spaces,
						"encoding",
					},
					lualine_y = {},
					lualine_z = { "location" },
				},
				inactive_sections = {
					lualine_a = {},
					lualine_b = {},
					lualine_c = { "filename" },
					lualine_x = { "location" },
					lualine_y = {},
					lualine_z = {},
				},
				extensions = { "nvim-tree", "toggleterm", "quickfix" },
			})
		end,
	},
}
