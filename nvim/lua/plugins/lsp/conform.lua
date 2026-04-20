return {
	"stevearc/conform.nvim",
	event = "BufWritePre",
	cmd = { "ConformInfo" },
	keys = {
		{
			"<leader>cF",
			function()
				require("conform").format({ async = true })
			end,
			desc = "Format",
			mode = { "n", "v" },
		},
	},
	opts = {
		formatters_by_ft = {
			go = { "gofmt", "goimports_reviser" },
			java = { "google-java-format" },
			kotlin = { "ktlint" },
			python = { "black" },
			typescript = { "prettierd" },
			typescriptreact = { "prettierd" },
			javascript = { "prettierd" },
			javascriptreact = { "prettierd" },
			html = { "prettierd" },
			css = { "prettierd" },
			json = { "prettierd" },
			sh = { "shfmt" },
			lua = { "stylua" },
		},
		formatters = {
			-- Configure prettierd to find the root config
			prettierd = {
				command = "prettierd",
				args = { "$FILENAME" },
				cwd = function(ctx)
					-- Find the nearest .prettierrc or package.json
					return vim.fs.dirname(vim.fs.find({
						".prettierrc",
						".prettierrc.json",
						".prettierrc.js",
						".prettierrc.mjs",
						"prettier.config.js",
						"prettier.config.mjs",
						"package.json",
					}, { upward = true })[1]) or ctx.dirname
				end,
			},
		},
		-- format_on_save respects the autoformat toggle from plugins.lsp.format
		format_on_save = function()
			local format = require("plugins.lsp.format")
			if not format.autoformat then
				return
			end
			return { timeout_ms = 3000, lsp_format = "fallback" }
		end,
	},
	config = function(_, opts)
		require("conform").setup(opts)
		-- Makes gq use conform for range formatting in visual mode
		vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
	end,
}
