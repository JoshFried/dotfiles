local prefix = "plugins.completions"
return {
    require(prefix .. ".nvim-cmp"),
    require(prefix .. ".luasnip"),
    require(prefix .. ".crates"),
}
