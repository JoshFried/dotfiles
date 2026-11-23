-- Import both Go plugin specs so go.nvim and Gopher contribute their commands.

local prefix = 'plugins.extra.lang.go'
return {
    require(prefix .. ".go"),
    require(prefix .. ".gopher"),
}
