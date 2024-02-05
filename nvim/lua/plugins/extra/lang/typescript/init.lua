local prefix = 'plugins.extra.lang.typescript'
return {
    {
        require(prefix .. ".lsp-config"),
        require(prefix .. ".mason"),
        require(prefix .. ".ts"),
        require(prefix .. ".typescript-tools"),
    }
}
