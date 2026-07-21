local M = {}

local lsp_utils = require("plugins.lsp.utils")
local icons = require("config.icons")

local function lsp_init()
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
                text = {
                    [vim.diagnostic.severity.ERROR] = icons.diagnostics.Error,
                    [vim.diagnostic.severity.WARN] = icons.diagnostics.Warning,
                    [vim.diagnostic.severity.HINT] = icons.diagnostics.Hint,
                    [vim.diagnostic.severity.INFO] = icons.diagnostics.Information,
                }
            },
            underline = false,
            update_in_insert = false,
            severity_sort = true,
            float = {
                focusable = true,
                style = "minimal",
                border = "rounded",
                source = true,
                header = "",
                prefix = "",
            },
            -- virtual_lines = true,
        },
    }

    -- Diagnostic configuration
    vim.diagnostic.config(config.diagnostic)

    -- Hover configuration
    -- vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, config.float)

    -- Signature help configuration
    -- vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, config.float)
end

function M.setup(_, opts)
    lsp_utils.on_attach(function(client, buffer)
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

    -- Registers a server with nvim's native LSP config API. vim.lsp.config()
    -- deep-merges our overrides with nvim-lspconfig's shipped defaults (lsp/*.lua),
    -- so we only declare what differs (settings, capabilities, on_init, ...).
    local function register(server, server_opts)
        server_opts.mason = nil -- spec-only flag, not an LSP config key
        vim.lsp.config(server, server_opts)
    end

    -- get all the servers that are available through mason-lspconfig
    local have_mason, mlsp = pcall(require, "mason-lspconfig")
    local all_mslp_servers = {}
    if have_mason then
        all_mslp_servers = vim.tbl_keys(mlsp.get_mappings().lspconfig_to_package)
    end

    local ensure_installed = {} ---@type string[]
    for server, server_opts in pairs(servers) do
        if server_opts then
            server_opts = server_opts == true and {} or server_opts
            local merged = vim.tbl_deep_extend("force", { capabilities = capabilities }, server_opts)

            -- Custom setup hooks (opts.setup.<server>); returning true skips
            -- the default registration below.
            local skip = false
            if opts.setup[server] then
                skip = opts.setup[server](server, merged)
            elseif opts.setup["*"] then
                skip = opts.setup["*"](server, merged)
            end

            if not skip then
                local use_mason = server_opts.mason ~= false and vim.tbl_contains(all_mslp_servers, server)
                register(server, merged)
                if use_mason then
                    -- mason-lspconfig v2's automatic_enable will vim.lsp.enable()
                    -- installed servers, picking up the config registered above.
                    -- (v1's `handlers` option is gone; passing it is silently ignored.)
                    ensure_installed[#ensure_installed + 1] = server
                else
                    vim.lsp.enable(server)
                end
            end
        end
    end

    if have_mason then
        mlsp.setup({
            ensure_installed = ensure_installed,
            -- jdtls is managed manually by nvim-jdtls (bemol workspace folders,
            -- lombok, per-project eclipse workspace) — don't auto-enable a
            -- second default-config instance.
            automatic_enable = { exclude = { "jdtls" } },
        })
    end
end

return M
