-- vtsls replaces typescript-tools. Uses VSCode's TS extension under the hood
-- for full feature parity (move refactor, rename file with import updates, etc.).
-- nvim-vtsls adds :VtsExec and :VtsRename helpers.
local utils = require("plugins.lsp.utils")

return {
    {
        "yioneko/nvim-vtsls",
        ft = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
        dependencies = { "neovim/nvim-lspconfig" },
    },
    {
        "neovim/nvim-lspconfig",
        dependencies = { "yioneko/nvim-vtsls" },
        opts = function(_, opts)
            opts.servers = opts.servers or {}

            opts.servers.vtsls = {
                settings = {
                    typescript = {
                        inlayHints = {
                            parameterNames = { enabled = "all", suppressWhenArgumentMatchesName = false },
                            parameterTypes = { enabled = true },
                            variableTypes = { enabled = true, suppressWhenTypeMatchesName = false },
                            propertyDeclarationTypes = { enabled = true },
                            functionLikeReturnTypes = { enabled = true },
                            enumMemberValues = { enabled = true },
                        },
                        preferences = {
                            quoteStyle = "auto",
                            preferTypeOnlyAutoImports = true,
                            includeCompletionsForModuleExports = true,
                        },
                        updateImportsOnFileMove = { enabled = "always" },
                        tsserver = { maxTsServerMemory = 8192 },
                    },
                    javascript = {
                        inlayHints = {
                            parameterNames = { enabled = "all", suppressWhenArgumentMatchesName = false },
                            parameterTypes = { enabled = true },
                            variableTypes = { enabled = true, suppressWhenTypeMatchesName = false },
                            propertyDeclarationTypes = { enabled = true },
                            functionLikeReturnTypes = { enabled = true },
                            enumMemberValues = { enabled = true },
                        },
                        updateImportsOnFileMove = { enabled = "always" },
                    },
                    vtsls = {
                        experimental = { completion = { enableServerSideFuzzyMatch = true } },
                    },
                },
            }

            opts.servers.eslint = {
                settings = {
                    workingDirectory = { mode = "auto" },
                },
            }

            opts.setup = opts.setup or {}
            opts.setup.vtsls = function()
                -- Register vtsls config with lspconfig (nvim-vtsls ships the config).
                local ok, vtsls = pcall(require, "vtsls")
                if ok then
                    require("lspconfig.configs").vtsls = vtsls.lspconfig
                end

                utils.on_attach(function(client, bufnr)
                    if client.name ~= "vtsls" then return end
                    local map = function(lhs, rhs, desc)
                        vim.keymap.set("n", lhs, rhs, { buffer = bufnr, desc = desc })
                    end
                    map("<leader>lo", "<cmd>VtsExec organize_imports<cr>",       "Organize Imports")
                    map("<leader>lO", "<cmd>VtsExec sort_imports<cr>",           "Sort Imports")
                    map("<leader>lA", "<cmd>VtsExec add_missing_imports<cr>",   "Add Missing Imports")
                    map("<leader>lR", "<cmd>VtsExec remove_unused_imports<cr>", "Remove Unused Imports")
                    map("<leader>lu", "<cmd>VtsExec remove_unused<cr>",         "Remove Unused")
                    map("<leader>lF", "<cmd>VtsExec fix_all<cr>",               "Fix All")
                    map("<leader>lz", "<cmd>VtsExec goto_source_definition<cr>","Go To Source Definition")
                    map("<leader>lr", "<cmd>VtsExec file_references<cr>",      "File References")
                    map("<leader>lM", "<cmd>VtsExec rename_file<cr>",           "Rename File (update imports)")
                end)
            end

            opts.setup.eslint = function()
                vim.api.nvim_create_autocmd("BufWritePre", {
                    callback = function(event)
                        local client = vim.lsp.get_clients({ bufnr = event.buf, name = "eslint" })[1]
                        if client then
                            local diag = vim.diagnostic.get(
                                event.buf,
                                { namespace = vim.lsp.diagnostic.get_namespace(client.id) }
                            )
                            if #diag > 0 then
                                vim.cmd("EslintFixAll")
                            end
                        end
                    end,
                })
            end

            return opts
        end,
    },
}
