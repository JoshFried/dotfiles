local transform_mod = require("telescope.actions.mt").transform_mod
-- local custom_actions = transform_mod({
-- 	-- File browser
-- 	file_browser = function(prompt_bufnr)
-- 		local content = require("telescope.actions.state").get_selected_entry()
-- 		if content == nil then
-- 			return
-- 		end

-- 		local full_path = content.cwd
-- 		if content.filename then
-- 			full_path = content.filename
-- 		elseif content.value then
-- 			full_path = full_path .. require("plenary.path").path.sep .. content.value
-- 		end

-- 		-- Close the Telescope window
-- 		require("telescope.actions").close(prompt_bufnr)

-- 		-- Open file browser
-- 		-- vim.cmd("Telescope file_browser select_buffer=true path=" .. vim.fs.dirname(full_path))
-- 		require("telescope").extensions.file_browser.file_browser({
-- 			select_buffer = true,
-- 			path = vim.fs.dirname(full_path),
-- 		})
-- 	end,
-- })

return {
	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
			-- "nvim-telescope/telescope-file-browser.nvim",
			"nvim-telescope/telescope-ui-select.nvim",
			"nvim-telescope/telescope-project.nvim",
			"ahmedkhalf/project.nvim",
			"cljoly/telescope-repo.nvim",
		},
		lazy = false,
		cmd = "Telescope",
		keys = {
			{
				"<leader>sf",
				function()
					require("telescope.builtin").find_files()
				end,
				desc = "[F]ind [F]iles",
			},
			{
				"<leader>sd",
				function()
					require("telescope.builtin").diagnostics()
				end,
				desc = "[S]earch [D]iagnostics",
			},
			{
				"<leader>tkm",
				function()
					require("telescope.builtin").keymaps()
				end,
				desc = "Keymaps",
			},
			{
				"<leader>zc",
				function()
					require("telescope.builtin").colorscheme({ enable_preview = true })
				end,
				desc = "Colorscheme",
			},
			{ "<leader>?", "<cmd>Telescope oldfiles<cr>", desc = "Recent" },
			{ "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
			-- { "<leader>fR", "<cmd>Telescope file_browser<cr>", desc = "Browser" },
			{ "<leader>ps", "<cmd>Telescope repo list<cr>", desc = "Search" },
			{ "<leader>hs", "<cmd>Telescope help_tags<cr>", desc = "Search" },
			{
				"<leader>/",
				function()
					require("telescope.builtin").current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
						winblend = 10,
						previewer = false,
						layout_config = {
							width = function(_, max_columns, _)
								return math.min(max_columns, 150)
							end,
						},
					}))
				end,
				{ desc = "[/] Fuzzily search in current buffer" },
			},
			{
				"<leader>pp",
				function()
					require("telescope.builtin").extensions.project.project({
						display_type = "minimal",
					})
				end,
				desc = "List",
			},
			{ "<leader>sg", "<cmd>Telescope live_grep<cr>", desc = "Workspace" },
			{
				"<leader>sb",
				function()
					require("telescope.builtin").current_buffer_fuzzy_find()
				end,
				desc = "Buffer",
			},
		},
		config = function(_, _)
			local telescope = require("telescope")
			local icons = require("config.icons")
			local actions = require("telescope.actions")
			local actions_layout = require("telescope.actions.layout")
			local mappings = {
				i = {
					["<C-j>"] = actions.move_selection_next,
					["<C-k>"] = actions.move_selection_previous,
					["<C-n>"] = actions.cycle_history_next,
					["<C-p>"] = actions.cycle_history_prev,
					["<A-p>"] = actions_layout.toggle_preview,
					["<C-h>"] = actions.select_horizontal,
					["<C-v>"] = actions.select_vertical,
					["<A-m>"] = actions_layout.toggle_mirror,
					-- ["<C-r>"] = custom_actions.file_browser,
				},
			}

			local opts = {
				defaults = {
					prompt_prefix = icons.ui.Telescope .. " ",
					selection_caret = icons.ui.Forward .. " ",
					mappings = mappings,
					border = {},
					borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
					color_devicons = true,
				},
				pickers = {
					find_files = {
						theme = "dropdown",
						previewer = false,
						hidden = true,
						find_command = { "rg", "--files", "--hidden", "-g", "!.git" },
					},
					git_files = {
						theme = "dropdown",
						previewer = false,
					},
					buffers = {
						theme = "dropdown",
						previewer = false,
					},
				},
				extensions = {
					-- file_browser = {
					-- 	theme = "dropdown",
					-- 	previewer = false,
					-- 	hijack_netrw = true,
					-- 	mappings = mappings,
					-- },
					project = {
						hidden_files = false,
						theme = "dropdown",
					},
					fzy_native = {
						override_generic_sorter = true,
						override_file_sorter = true,
					},
					fzf_writer = {
						use_highlighter = false,
						minimum_grep_characters = 6,
					},
					["ui-select"] = {
						-- this makes it so RustDebuggables are readable without needing to wrap text
						require("telescope.themes").get_dropdown({
							layout_config = {
								width = function(_, max_columns, _)
									return math.min(max_columns, 150)
								end,
							},
						}),
					},
				},
			}
			telescope.setup(opts)
			telescope.load_extension("fzf")
			-- telescope.load_extension("file_browser")
			telescope.load_extension("project")
			telescope.load_extension("projects")
			telescope.load_extension("ui-select")
		end,
	},
	{
		"ahmedkhalf/project.nvim",
		config = function()
			require("project_nvim").setup({
				detection_methods = { "pattern", "lsp" },
				patterns = { ".git" },
				ignore_lsp = { "null-ls" },
			})
		end,
	},
}
