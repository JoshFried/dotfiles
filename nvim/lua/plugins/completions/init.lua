local prefix = "plugins.completions"
return {
    {
        "ray-x/lsp_signature.nvim",
        event = "VeryLazy",
        config = function(_, opts) require 'lsp_signature'.setup(opts) end
    },

    require(prefix .. ".crates"),
    require(prefix .. ".luasnip"),
    require(prefix .. ".nvim-cmp"),
}
