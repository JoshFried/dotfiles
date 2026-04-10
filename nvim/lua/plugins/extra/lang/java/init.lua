local prefix = 'plugins.extra.lang.java'

return {
    {
        require(prefix .. ".ts"),
        require(prefix .. ".jdtls"),
        require(prefix .. ".mason"),
        require(prefix .. ".lspconfig"),
    }
}
