local ignoredNavBuddyClients = {
    ["eslint"] = true,
    ["null-ls"] = true,
    ["golangci_lint_ls"] = true,
    ["tsserver"] = true
}

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
        opts = {},
        config = function()
            local lsp_utils = require("plugins.lsp.utils")
            lsp_utils.on_attach(function(client, buffer)
                if ignoredNavBuddyClients[client.name] == nil then
                    local navbuddy = require("nvim-navbuddy")
                    navbuddy.attach(client, buffer)
                end
            end)
        end,
    },
}
