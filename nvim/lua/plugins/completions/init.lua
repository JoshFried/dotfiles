-- Collect the Blink completion engine, LuaSnip expansion and Cargo manifest helpers
-- into one lazy.nvim spec.

local prefix = "plugins.completions"
return {
    require(prefix .. ".blink"),
    require(prefix .. ".luasnip"),
    require(prefix .. ".crates"),
}
