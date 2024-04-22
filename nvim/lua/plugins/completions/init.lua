local prefix = "plugins.completions"
return {
    {
        "ray-x/lsp_signature.nvim",
        event = "VeryLazy",
        enabled = false,
        config = function(_, opts) require 'lsp_signature'.setup(opts) end
    },

    require(prefix .. ".luasnip"),
    require(prefix .. ".nvim-cmp"),
    require(prefix .. ".codeium"),
    require(prefix .. ".crates"),
}
