local M = {}

local lsp_utils = require("plugins.lsp.utils")
local icons = require("config.icons")

local function lsp_init()
    local signs = {
        { name = "DiagnosticSignError", text = icons.diagnostics.Error },
        { name = "DiagnosticSignWarn",  text = icons.diagnostics.Warning },
        { name = "DiagnosticSignHint",  text = icons.diagnostics.Hint },
        { name = "DiagnosticSignInfo",  text = icons.diagnostics.Info },
    }
    for _, sign in ipairs(signs) do
        vim.fn.sign_define(sign.name, { texthl = sign.name, text = sign.text, numhl = sign.name })
    end

    -- LSP handlers configuration
    local config = {
        float = {
            focusable = true,
            style = "minimal",
            border = "rounded",
        },

        diagnostic = {
            virtual_text = {
                severity = {
                    min = vim.diagnostic.severity.ERROR,
                },
            },
            signs = {
                active = signs,
            },
            underline = false,
            update_in_insert = false,
            severity_sort = true,
            float = {
                focusable = true,
                style = "minimal",
                border = "rounded",
                source = "always",
                header = "",
                prefix = "",
            },
            -- virtual_lines = true,
        },
    }

    -- Diagnostic configuration
    vim.diagnostic.config(config.diagnostic)

    -- Hover configuration
    vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, config.float)

    -- Signature help configuration
    vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, config.float)
end

function M.setup(_, opts)
    local lsp_utils_ok, lsp_utils = pcall(require, "plugins.lsp.utils")
    if not lsp_utils_ok then
        vim.notify("Failed to load LSP utils", vim.log.levels.ERROR)
        return
    end

    lsp_utils.on_attach(function(client, buffer)
        local format_ok, format = pcall(require, "plugins.lsp.format")
        if format_ok then
            format.on_attach(client, buffer)
        else
            vim.notify("Failed to load LSP format", vim.log.levels.WARN)
        end

        local keymaps_ok, keymaps = pcall(require, "plugins.lsp.keymaps")
        if keymaps_ok then
            keymaps.on_attach(client, buffer)
        else
            vim.notify("Failed to load LSP keymaps", vim.log.levels.WARN)
        end
    end)

    lsp_init() -- diagnostics, handlers

    local servers = opts.servers
    local capabilities = lsp_utils.capabilities()

    local function setup(server)
        local server_opts = vim.tbl_deep_extend("force", {
            capabilities = capabilities,
        }, servers[server] or {})
        if opts.setup[server] then
            if opts.setup[server](server, server_opts) then
                return
            end
        elseif opts.setup["*"] then
            if opts.setup["*"](server, server_opts) then
                return
            end
        end
        require("lspconfig")[server].setup(server_opts)
    end

    -- get all the servers that are available thourgh mason-lspconfig
    local have_mason, mlsp = pcall(require, "mason-lspconfig")
    local all_mslp_servers = {}
    if have_mason then
        all_mslp_servers = vim.tbl_keys(require("mason-lspconfig").get_mappings().lspconfig_to_package)
    end

    local ensure_installed = {} ---@type string[]
    for server, server_opts in pairs(servers) do
        if server_opts then
            server_opts = server_opts == true and {} or server_opts
            if server_opts.mason == false or not vim.tbl_contains(all_mslp_servers, server) then
                setup(server)
            else
                ensure_installed[#ensure_installed + 1] = server
            end
        end
    end

    if have_mason then
        mlsp.setup({ ensure_installed = ensure_installed })
        mlsp.setup({ setup })
    end
end

return M
