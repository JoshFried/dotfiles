local prefix = 'plugins.extra.lang.go'
return {
    {
        require(prefix .. ".go"),
        require(prefix .. ".gopher"),
        require(prefix .. '.null-ls'),
    }
}
