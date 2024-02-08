local M = {
    "mrcjkb/rustaceanvim",
    -- version = "^3", -- Recommended
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
                    local inlays = require('lsp-inlayhints')
                    inlays.setup()
                    local bufnr = vim.api.nvim_get_current_buf()
                    vim.keymap.set(
                        "n",
                        "<leader>a",
                        function()
                            vim.cmd.RustLsp('codeAction') -- supports rust-analyzer's grouping
                            -- or vim.lsp.buf.codeAction() if you don't want grouping.
                        end,
                        { silent = true, buffer = bufnr }
                    )

                    vim.keymap.set(
                        "n",
                        "<leader>Rd",
                        "<cmd>RustLsp debuggables<CR>",
                        { buffer = bufnr, desc = "Debuggables" }
                    )

                    vim.keymap.set(
                        "n",
                        "<leader>Rt",
                        "<cmd>RustLsp testables<CR>",
                        { buffer = bufnr, desc = "Testables" }
                    )

                    vim.keymap.set(
                        "n",
                        "<leader>ha",
                        "<cmd>RustLsp hover actions<CR>",
                        { buffer = bufnr, desc = "Hover Actions" }
                    )
                    vim.keymap.set(
                        "n",
                        "<leader>roc",
                        "<cmd>RustLsp openCargo<CR>",
                        { buffer = bufnr, desc = "Open Cargo" }
                    )
                    vim.keymap.set(
                        "n",
                        "<leader>rpm",
                        "<cmd>RustLsp parentModule<CR>",
                        { buffer = bufnr, desc = "Parent Module" }
                    )
                    vim.keymap.set("n", "<leader>cl", function()
                        vim.lsp.codelens.run()
                    end, { buffer = bufnr, desc = "Code Lens" })

                    vim.keymap.set(
                        "n",
                        "<leader>reh",
                        function()
                            require('lsp-inlayhints').toggle()
                        end,
                        { buffer = buffer, desc = "Parent Module" }
                    )
                    inlays.on_attach(client, buffer)
                    require('lsp_signature').on_attach()
                end,
                settings = {
                    -- rust-analyzer language server configuration
                    ["rust-analyzer"] = {
                        cargo = {
                            allFeatures = true,
                        },
                        -- Add clippy lints for Rust.
                        checkOnSave = {
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
            inlay_hints = {
                highlight = "NonText",
            },
            dap = {
                adapter = cfg.get_codelldb_adapter(codelldb_path, liblldb_path),
            },
            tools = {
                autoSetHints = true,
                inlay_hints = {
                    show_parameter_hints = true,
                    parameter_hints_prefix = "in: ", -- "<- ",
                    other_hints_prefix = "out: "     -- "=> "
                },
                on_initialized = function()
                    vim.api.nvim_create_autocmd(
                        { "BufWritePost", "BufEnter", "CursorHold", "InsertLeave", },
                        {
                            pattern = { "*.rs" },
                            callback = function()
                                vim.lsp.codelens.refresh()
                            end,
                        }
                    )
                end,
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
