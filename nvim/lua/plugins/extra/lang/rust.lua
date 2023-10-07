-- -- local install_root_dir = vim.fn.stdpath("data") .. "/mason"
-- local extension_path = vim.fn.expand("~/.vscode/extensions/vadimcn.vscode-lldb-1.9.0/")
-- local codelldb_path = extension_path .. "adapter/codelldb"
-- local liblldb_path = extension_path .. "lldb/lib/liblldb.dylib"
-- local _, rust_analyzer_cmd = nil, { "rustup", "run", "stable", "rust-analyzer" }

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
        "neovim/nvim-lspconfig",
        dependencies = { "simrat39/rust-tools.nvim", "rust-lang/rust.vim" },
        opts = {
            servers = {
                rust_analyzer = {
                    settings = {
                        ["rust-analyzer"] = {
                            cargo = { allFeatures = true },
                            check = {
                                command = "clippy",
                                extraArgs = { "--no-deps" },
                            },
                            imports = {
                                prefix = "crate",
                            },
                        },
                    },
                },
            },
            setup = {
                rust_analyzer = function(_, opts)
                    local codelldb_path, liblldb_path = get_codelldb()

                    local lsp_utils = require("plugins.lsp.utils")
                    lsp_utils.on_attach(function(client, buffer)
                        if client.name == "rust_analyzer" then
                            vim.keymap.set(
                                "n",
                                "<leader>Rd",
                                "<cmd>RustDebuggables<CR>",
                                { buffer = buffer, desc = "Debuggables" }
                            )
                            vim.keymap.set(
                                "n",
                                "<leader>ha",
                                "<cmd>RustHoverActions<CR>",
                                { buffer = buffer, desc = "Hover Actions" }
                            )
                            vim.keymap.set(
                                "n",
                                "<leader>roc",
                                "<cmd>RustOpenCargo<CR>",
                                { buffer = buffer, desc = "Open Cargo" }
                            )
                            vim.keymap.set(
                                "n",
                                "<leader>rpm",
                                "<cmd>RustParentModule<CR>",
                                { buffer = buffer, desc = "Parent Module" }
                            )
                            vim.keymap.set("n", "<leader>cl", function()
                                vim.lsp.codelens.run()
                            end, { buffer = buffer, desc = "Code Lens" })
                        end
                    end)

                    require("rust-tools").setup({
                        tools = {
                            runnables = {
                                use_telescope = true,
                            },
                            debuggables = {
                                use_telescope = false,
                            },
                            inlay_hints = {
                                auto = true,
                                show_parameter_hints = true,
                                parameter_hints_prefix = "",
                                other_hints_prefix = "-> ",
                            },
                            hover_actions = {
                                auto_focus = true,
                                border = "solid",
                            },
                            on_initialized = function()
                                vim.api.nvim_create_autocmd(
                                    { "BufWritePost", "BufEnter", "CursorHold", "InsertLeave" },
                                    {
                                        pattern = { "*.rs" },
                                        callback = function()
                                            vim.lsp.codelens.refresh()
                                        end,
                                    }
                                )
                            end,
                        },
                        server = opts,
                        dap = {
                            adapter = require("rust-tools.dap").get_codelldb_adapter(codelldb_path, liblldb_path),
                        },
                    })
                    return true
                end,
            },
        },
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
