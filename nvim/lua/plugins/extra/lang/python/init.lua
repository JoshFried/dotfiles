local prefix = 'plugins.extra.lang.python'
return {
    {
        require(prefix .. ".dap"),
        require(prefix .. ".lsp"),
        require(prefix .. ".mason"),
        require(prefix .. ".neotest"),
        require(prefix .. ".null-ls"),
        require(prefix .. ".ts"),
        require(prefix .. ".type-stubs"),
        require(prefix .. ".venv-selector"),
    }
}
