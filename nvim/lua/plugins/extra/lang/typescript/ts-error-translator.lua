-- Attach the TypeScript error translator to supported JavaScript and TypeScript
-- language servers for more readable diagnostics.

return {
	"dmmulroy/ts-error-translator.nvim",
	ft = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
	opts = {
		auto_attach = true,
		servers = {
			"ts_ls",
			"volar",
			"vtsls",
		},
	},
}
