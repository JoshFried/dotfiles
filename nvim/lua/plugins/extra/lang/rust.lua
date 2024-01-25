local function get_codelldb()
    local mason_registry = require("mason-registry")
    local codelldb = mason_registry.get_package("codelldb")
    local extension_path = codelldb:get_install_path() .. "/extension/"
    local codelldb_path = extension_path .. "adapter/codelldb"
    local liblldb_path = extension_path .. "lldb/lib/liblldb.dylib"
    return codelldb_path, liblldb_path
end

return {
    {
        "nvim-treesitter/nvim-treesitter",
        opts = function(_, opts)
            vim.list_extend(opts.ensure_installed, { "rust" })
        end,
    },
    {
        "mrcjkb/rustaceanvim",
        version = "^3", -- Recommended
        ft = { "rust" },
        config = function(_, opts)
            local codelldb_path, liblldb_path = get_codelldb()
            local cfg = require('rustaceanvim.config')
            vim.g.rustaceanvim = function()
                return {
                    server = {
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
                    dap = {
                        adapter = cfg.get_codelldb_adapter(codelldb_path, liblldb_path),
                    },
                    tools = {
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
                        runnables = {
                            use_telescope = true,
                        },
                        debuggables = {
                            use_telescope = true,
                        },
                    },
                }
            end
        end
    },
    {
        "mfussenegger/nvim-dap",
        opts = {
            setup = {
                codelldb = function()
                    local codelldb_path, liblldb_path = get_codelldb()
                    local dap = require("dap")
                    dap.adapters.codelldb = {
                        type = "server",
                        port = "${port}",
                        executable = {
                            command = codelldb_path,
                            args = { "--port", "${port}" },
                        },
                    }
                    dap.configurations.cpp = {
                        {
                            name = "Launch file",
                            type = "codelldb",
                            request = "launch",
                            program = function()
                                return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
                            end,
                            cwd = "${workspaceFolder}",
                            stopOnEntry = false,
                        },
                    }

                    dap.configurations.c = dap.configurations.cpp
                    dap.configurations.rust = dap.configurations.cpp
                end,
            },
        },
    },
}
