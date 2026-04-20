return {
	"saghen/blink.cmp",
	event = "InsertEnter",
	version = "*",
	build = "cargo build --release",
	dependencies = {
		"L3MON4D3/LuaSnip",
		"rafamadriz/friendly-snippets",
		{ "saghen/blink.compat", version = "*", opts = {} },
	},
	---@module 'blink.cmp'
	---@type blink.cmp.Config
	opts = {
		keymap = {
			preset = "default",
			["<C-n>"] = {
				function(cmp)
					if cmp.is_visible() then return cmp.select_next() end
					local luasnip = require("luasnip")
					if luasnip.jumpable(1) then luasnip.jump(1); return true end
				end,
				"fallback",
			},
			["<C-p>"] = {
				function(cmp)
					if cmp.is_visible() then return cmp.select_prev() end
					local luasnip = require("luasnip")
					if luasnip.jumpable(-1) then luasnip.jump(-1); return true end
				end,
				"fallback",
			},
		},

		appearance = {
			use_nvim_cmp_as_default = false,
			nerd_font_variant = "mono",
			kind_icons = require("config.icons").kind,
		},

		snippets = { preset = "luasnip" },

		completion = {
			accept = { auto_brackets = { enabled = true } },
			menu = {
				border = "rounded",
				draw = {
					columns = {
						{ "kind_icon" },
						{ "label", "label_description", gap = 1 },
						{ "source_name" },
					},
				},
			},
			documentation = {
				auto_show = true,
				auto_show_delay_ms = 200,
				window = { border = "rounded" },
			},
			ghost_text = { enabled = true },
		},

		-- Noice handles signature help via lsp_doc_border preset.
		signature = { enabled = false },

		sources = {
			default = { "lsp", "path", "snippets", "buffer", "lazydev" },
			per_filetype = {
				["toml"] = { "lsp", "path", "snippets", "buffer", "crates" },
				["json"] = { "lsp", "path", "snippets", "buffer", "npm" },
				["sql"] = { "lsp", "path", "snippets", "buffer", "omni" },
				["mysql"] = { "lsp", "path", "snippets", "buffer", "omni" },
				["plsql"] = { "lsp", "path", "snippets", "buffer", "omni" },
			},
			providers = {
				lazydev = {
					name = "LazyDev",
					module = "lazydev.integrations.blink",
					score_offset = 100,
				},
				crates = {
					name = "crates",
					module = "blink.compat.source",
					score_offset = 100,
				},
				npm = {
					name = "npm",
					module = "blink.compat.source",
					score_offset = 100,
				},
			},
		},

		fuzzy = { implementation = "prefer_rust_with_warning" },
	},
	opts_extend = { "sources.default" },
}
