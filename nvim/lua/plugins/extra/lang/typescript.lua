return {
	{
		"nvim-treesitter/nvim-treesitter",
		opts = function(_, opts)
			vim.list_extend(opts.ensure_installed, { "javascript", "typescript", "tsx" })
		end,
	},
	{
		"williamboman/mason.nvim",
		opts = function(_, opts)
			vim.list_extend(opts.ensure_installed, { "typescript-language-server", "js-debug-adapter" })
		end,
	},
	{
		"pmizio/typescript-tools.nvim",
		dependencies = { "folke/neoconf.nvim", cmd = "Neoconf", config = true },
		opts = {},
		config = function(_, opts)
			require("plugins.lsp.utils").on_attach(function(client, bufnr)
				if client.name == "tsserver" then
					vim.keymap.set(
						"n",
						"<leader>lo",
						"<cmd>TSToolsOrganizeImports<cr>",
						{ buffer = bufnr, desc = "Organize Imports" }
					)
					vim.keymap.set(
						"n",
						"<leader>lO",
						"<cmd>TSToolsSortImports<cr>",
						{ buffer = bufnr, desc = "Sort Imports" }
					)
					vim.keymap.set(
						"n",
						"<leader>lu",
						"<cmd>TSToolsRemoveUnused<cr>",
						{ buffer = bufnr, desc = "Removed Unused" }
					)
					vim.keymap.set(
						"n",
						"<leader>lz",
						"<cmd>TSToolsGoToSourceDefinition<cr>",
						{ buffer = bufnr, desc = "Go To Source Definition" }
					)
					vim.keymap.set(
						"n",
						"<leader>lR",
						"<cmd>TSToolsRemoveUnusedImports<cr>",
						{ buffer = bufnr, desc = "Removed Unused Imports" }
					)
					vim.keymap.set("n", "<leader>lF", "<cmd>TSToolsFixAll<cr>", { buffer = bufnr, desc = "Fix All" })
					vim.keymap.set(
						"n",
						"<leader>lA",
						"<cmd>TSToolsAddMissingImports<cr>",
						{ buffer = bufnr, desc = "Add Missing Imports" }
					)
				end
			end)
			require("typescript-tools").setup(opts)
		end,
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = { "pmizio/typescript-tools.nvim" },
		opts = {
			-- make sure mason installs the server
			servers = {
				-- ESLint
				eslint = {
					settings = {
						-- helps eslint find the eslintrc when it's placed in a subfolder instead of the cwd root
						workingDirectory = { mode = "auto" },
					},
				},
			},
			setup = {
				eslint = function()
					vim.api.nvim_create_autocmd("BufWritePre", {
						callback = function(event)
							local client = vim.lsp.get_active_clients({ bufnr = event.buf, name = "eslint" })[1]
							if client then
								local diag = vim.diagnostic.get(
									event.buf,
									{ namespace = vim.lsp.diagnostic.get_namespace(client.id) }
								)
								if #diag > 0 then
									vim.cmd("EslintFixAll")
								end
							end
						end,
					})
				end,
			},
		},
	},
}
