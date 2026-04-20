local prefix = "plugins.completions"
return {
    require(prefix .. ".blink"),
    require(prefix .. ".luasnip"),
    require(prefix .. ".crates"),
}
