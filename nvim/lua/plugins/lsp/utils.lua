local M = {}

function M.list_formatters(ft)
    local ok, conform = pcall(require, "conform")
    if ok then
        local formatters = conform.list_formatters_for_buffer()
        local names = {}
        for _, f in ipairs(formatters) do
            table.insert(names, type(f) == "string" and f or f.name)
        end
        return names
    end
    return {}
end

function M.list_linters(ft)
    local ok, lint = pcall(require, "lint")
    if ok then
        return lint.linters_by_ft[ft] or {}
    end
    return {}
end

function M.capabilities()
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities.textDocument.completion.completionItem.snippetSupport = true
    capabilities.textDocument.foldingRange = {
        dynamicRegistration = false,
        lineFoldingOnly = true,
    }
    return require("cmp_nvim_lsp").default_capabilities(capabilities)
end

function M.on_attach(on_attach)
    vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
            local bufnr = args.buf
            local client = vim.lsp.get_client_by_id(args.data.client_id)
            on_attach(client, bufnr)
        end,
    })
end

local diagnostics_active = true

function M.show_diagnostics()
    return diagnostics_active
end

function M.toggle_diagnostics()
    diagnostics_active = not diagnostics_active
    if diagnostics_active then
        vim.diagnostic.show()
    else
        vim.diagnostic.hide()
    end
end

function M.opts(name)
    local plugin = require("lazy.core.config").plugins[name]
    if not plugin then
        return {}
    end
    local Plugin = require("lazy.core.plugin")
    return Plugin.values(plugin, "opts", false)
end

return M
