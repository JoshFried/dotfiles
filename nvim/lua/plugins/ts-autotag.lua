return {
	"windwp/nvim-ts-autotag",
	-- was `lazy = true` with no trigger, so it never loaded; load on the
	-- filetypes it actually operates on
	ft = {
		"html",
		"xml",
		"javascriptreact",
		"typescriptreact",
		"vue",
		"svelte",
		"markdown",
	},

	config = function()
		require("nvim-ts-autotag").setup({})
	end,
}
