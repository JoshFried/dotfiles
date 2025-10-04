local M = {
    "mrcjkb/rustaceanvim",
    ft = { "rust" },
    dependencies = {
        "nvim-lua/plenary.nvim",
        "mfussenegger/nvim-dap",
        "lvimuser/lsp-inlayhints.nvim",
    },
}

M.config = function(_, _)
    local codelldb_path, liblldb_path = Get_codelldb()
    local cfg = require('rustaceanvim.config')
    vim.g.rustaceanvim = function()
        return {
            server = {
                on_attach = function(client, buffer)
                    vim.keymap.set("n", "<leader>cL", function()
                        vim.lsp.codelens.refresh()
                    end, { buffer = buffer, desc = "refresh code lense" })


                    vim.keymap.set("n", "<leader>Cl", function()
                        vim.lsp.codelens.clear()
                    end, { buffer = buffer, desc = "refresh code lense" })


                    vim.keymap.set(
                        "n",
                        "<leader>a",
                        function()
                            vim.cmd.RustLsp('codeAction') -- supports rust-analyzer's grouping
                            -- or vim.lsp.buf.codeAction() if you don't want grouping.
                        end,
                        { silent = true, buffer = buffer }
                    )

                    vim.keymap.set(
                        "n",
                        "<leader>Rd",
                        "<cmd>RustLsp debuggables<CR>",
                        { buffer = buffer, desc = "Debuggables" }
                    )

                    vim.keymap.set(
                        "n",
                        "<leader>Rt",
                        "<cmd>RustLsp testables<CR>",
                        { buffer = buffer, desc = "Testables" }
                    )

                    vim.keymap.set(
                        "n",
                        "<leader>ha",
                        "<cmd>RustLsp hover actions<CR>",
                        { buffer = buffer, desc = "Hover Actions" }
                    )
                    vim.keymap.set(
                        "n",
                        "<leader>roc",
                        "<cmd>RustLsp openCargo<CR>",
                        { buffer = buffer, desc = "Open Cargo" }
                    )
                    vim.keymap.set(
                        "n",
                        "<leader>rpm",
                        "<cmd>RustLsp parentModule<CR>",
                        { buffer = buffer, desc = "Parent Module" }
                    )
                    vim.keymap.set("n", "<leader>cl", function()
                        vim.lsp.codelens.run()
                    end, { buffer = buffer, desc = "Code Lens" })
                end,
                settings = {
                    -- rust-analyzer language server configuration
                    ["rust-analyzer"] = {
                        cargo = {
                            allFeatures = true,
                            loadOutDirsFromCheck = true
                        },
                        diagnostics = {
                            -- styleLints = {
                            --     enable = true
                            -- },
                            disabled = {
                                "unresolved-proc-macro", -- nice
                            },
                        },
                        -- Add clippy lints for Rust.
                        checkOnSave = {
                            allFeatures = true,
                            command = "clippy",
                            extraArgs = { "--no-deps" },
                        },
                        imports = {
                            granularity = {
                                group = "crate"
                            },
                            prefix = "crate",
                        },
                        inlayHints = {
                            lifeTimeElisionHints = {
                                enable = true,
                                useParameterNames = true
                            },
                            closureCaptureHints = {
                                enable = true,
                            },
                            closureReturnTypeHints = {
                                enable = true,
                            },
                            parameterHints = {
                                enable = true
                            },
                            chainingHints = {
                                enable = true
                            }
                        },
                        procMacro = {
                            enable = true,
                            ignored = {
                                ["async-trait"] = { "async_trait" },
                                ["napi-derive"] = { "napi" },
                                ["async-recursion"] = { "async_recursion" },
                            },
                        },
                    },
                },
            },
            default_settings = {
                ['rust_analyzer'] = {
                    server = {
                        extraEnv = {
                            RUSTUP_TOOLCHAIN = "stable",
                        }
                    },
                },
            },
            inlay_hints = {
                highlight = "NonText",
            },
            dap = {
                -- adapter = cfg.get_codelldb_adapter(codelldb_path, liblldb_path),
            },
            tools = {
                autoSetHints = true,
                inlay_hints = {
                    show_parameter_hints = true,
                    parameter_hints_prefix = "in: ", -- "<- ",
                    other_hints_prefix = "out: "     -- "=> "
                },
                hover_actions = {
                    auto_focus = true,
                    border = "solid",
                },
            },
        }
    end
end

M.keys = {
    { "<leader>?", "<cmd>Telescope oldfiles<cr>", desc = "Recent" },
}

return M
