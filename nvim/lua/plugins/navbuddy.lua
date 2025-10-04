return {
    {
        "SmiteshP/nvim-navbuddy",
        event = "VeryLazy",
        dependencies = {
            "neovim/nvim-lspconfig",
            "SmiteshP/nvim-navic",
            "MunifTanjim/nui.nvim",
        },
        --stylua: ignore
        keys = {
            { "<leader>vo", function() require("nvim-navbuddy").open() end, desc = "Code Outline (navbuddy)", },
        },
        opts = {
            lsp = {
                preference = {
                    -- "tsserver",
                }
            }
        },
        config = function()
            local lsp_utils = require("plugins.lsp.utils")

            lsp_utils.on_attach(function(client, buffer)
                vim.g.navic_silence = true
                if client.server_capabilities.documentSymbolProvider then
                    local navbuddy = require("nvim-navbuddy")
                    navbuddy.attach(client, buffer)
                end
            end)
        end,
    },
}
