-- Import Python-specific debugging, language server, installer, test and editing
-- specs.

local prefix = 'plugins.extra.lang.python'
return {
    require(prefix .. ".dap"),
    require(prefix .. ".lsp"),
    require(prefix .. ".mason"),
    require(prefix .. ".neotest"),
    require(prefix .. ".ts"),
    require(prefix .. ".type-stubs"),
    require(prefix .. ".venv-selector"),
}
