return {
    {
        "neovim/nvim-lspconfig",
        event = "BufReadPre",
        dependencies = {
            {
                "folke/lazydev.nvim",
                opts = {
                    library = {
                        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
                        { path = "neotest" },
                        { path = "nvim-dap-ui" }
                    },
                },
            },
            { "j-hui/fidget.nvim", config = true },
            {
                "smjonas/inc-rename.nvim", config = true
            },
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
        },
        opts = {
            servers = {
                lua_ls = {
                    settings = {
                        Lua = {
                            workspace = {
                                checkThirdParty = false,
                            },
                            completion = { callSnippet = "Replace" },
                            telemetry = { enable = false },
                            hint = {
                                enable = false,
                            },
                        },
                    },
                },
                dockerls = {},
                marksman = {},
                lemminx = {},
                prismals = {},
                smithy_ls = {}
            },
            setup = {
                lua_ls = function(_, _)
                    local lsp_utils = require("plugins.lsp.utils")
                    lsp_utils.on_attach(function(client, buffer)
                        if client.name == "lua_ls" then
                            vim.keymap.set("n", "<leader>dX", function()
                                require("osv").run_this()
                            end, { buffer = buffer, desc = "OSV Run" })
                            vim.keymap.set("n", "<leader>dL", function()
                                require("osv").launch({ port = 8086 })
                            end, { buffer = buffer, desc = "OSV Launch" })
                        end
                    end)
                end,
            },
        },
        config = function(plugin, opts)
            require("plugins.lsp.servers").setup(plugin, opts)
        end,
    },
    {
        "williamboman/mason.nvim",
        cmd = "Mason",
        keys = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" } },
        opts = {
            ensure_installed = {
                "stylua",
                "ruff",
                "codelldb",
                "debugpy",
                "ktlint",
            },
        },
        config = function(_, opts)
            require("mason").setup()
            local mr = require("mason-registry")
            for _, tool in ipairs(opts.ensure_installed) do
                local p = mr.get_package(tool)
                if not p:is_installed() then
                    p:install()
                end
            end
        end,
    },
    require("plugins.lsp.conform"),
    require("plugins.lsp.nvim-lint"),
}
