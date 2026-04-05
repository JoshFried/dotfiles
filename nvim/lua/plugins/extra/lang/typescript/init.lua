local prefix = 'plugins.extra.lang.typescript'
return {
    {
        require(prefix .. ".lsp-config"),
        require(prefix .. ".ts-error-translator"),
        require(prefix .. ".mason"),
        require(prefix .. ".null-ls"),
        require(prefix .. ".ts"),
        require(prefix .. ".typescript-tools"),
    }
}
