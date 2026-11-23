-- Collect TypeScript server, tooling, parser and package.json integrations into the
-- language import.

local prefix = 'plugins.extra.lang.typescript'
return {
    require(prefix .. ".lsp-config"),
    require(prefix .. ".ts-error-translator"),
    require(prefix .. ".mason"),
    require(prefix .. ".ts"),
    require(prefix .. ".package-info"),
}
