local M = {
    "neovim/nvim-lspconfig",
    opts = {
        servers = {
            ruff_lsp = {},
            pyright = {
                settings = {
                    python = {
                        analysis = {
                            autoImportCompletions = true,
                            typeCheckingMode = "on",
                            autoSearchPaths = true,
                            useLibraryCodeForTypes = true,
                            diagnosticMode = "openFilesOnly",
                            stubPath = vim.fn.stdpath "data" .. "/lazy/python-type-stubs/stubs",
                        },
                    },
                },
            },
        },
        setup = {
            ruff_lsp = function()
                local lsp_utils = require "plugins.lsp.utils"
                lsp_utils.on_attach(function(client, _)
                    if client.name == "ruff_lsp" then
                        -- Disable hover in favor of Pyright
                        client.server_capabilities.hoverProvider = false
                    end
                end)
            end,
            pyright = function(_, _)
                local lsp_utils = require "plugins.lsp.utils"
                lsp_utils.on_attach(function(client, bufnr)
                    local map = function(mode, lhs, rhs, desc)
                        if desc then
                            desc = desc
                        end
                        vim.keymap.set(mode, lhs, rhs, { silent = true, desc = desc, buffer = bufnr, noremap = true })
                    end
                    -- stylua: ignore
                    if client.name == "pyright" then
                        map("n", "<leader>lo", "<cmd>PyrightOrganizeImports<cr>", "Organize Imports")
                        map("n", "<leader>lC", function() require("dap-python").test_class() end, "Debug Class")
                        map("n", "<leader>lM", function() require("dap-python").test_method() end, "Debug Method")
                        map("v", "<leader>lE", function() require("dap-python").debug_selection() end,
                            "Debug Selection")
                    end
                end)
            end,
        },
    },
}


return M
