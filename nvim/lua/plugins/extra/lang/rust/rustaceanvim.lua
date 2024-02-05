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

return M
