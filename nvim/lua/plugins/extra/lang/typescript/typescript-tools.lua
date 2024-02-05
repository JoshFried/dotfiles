local M = {
    "pmizio/typescript-tools.nvim",
    dependencies = { "folke/neoconf.nvim", cmd = "Neoconf", config = true },
    opts = {
        tsserver_file_preferences = {
            -- Inlay Hints
            includeInlayParameterNameHints = "all",
            includeInlayParameterNameHintsWhenArgumentMatchesName = true,
            includeInlayFunctionParameterTypeHints = true,
            includeInlayVariableTypeHints = true,
            includeInlayVariableTypeHintsWhenTypeMatchesName = true,
            includeInlayPropertyDeclarationTypeHints = true,
            includeInlayFunctionLikeReturnTypeHints = true,
            includeInlayEnumMemberValueHints = true,
        },
    },
}

M.config = function(_, opts)
    require("plugins.lsp.utils").on_attach(function(client, bufnr)
        if client.name == "tsserver" then
            vim.keymap.set(
                "n",
                "<leader>lo",
                "<cmd>TSToolsOrganizeImports<cr>",
                { buffer = bufnr, desc = "Organize Imports" }
            )
            vim.keymap.set(
                "n",
                "<leader>lO",
                "<cmd>TSToolsSortImports<cr>",
                { buffer = bufnr, desc = "Sort Imports" }
            )
            vim.keymap.set(
                "n",
                "<leader>lu",
                "<cmd>TSToolsRemoveUnused<cr>",
                { buffer = bufnr, desc = "Removed Unused" }
            )
            vim.keymap.set(
                "n",
                "<leader>lz",
                "<cmd>TSToolsGoToSourceDefinition<cr>",
                { buffer = bufnr, desc = "Go To Source Definition" }
            )
            vim.keymap.set(
                "n",
                "<leader>lR",
                "<cmd>TSToolsRemoveUnusedImports<cr>",
                { buffer = bufnr, desc = "Removed Unused Imports" }
            )
            vim.keymap.set("n", "<leader>lF", "<cmd>TSToolsFixAll<cr>", { buffer = bufnr, desc = "Fix All" })
            vim.keymap.set(
                "n",
                "<leader>lA",
                "<cmd>TSToolsAddMissingImports<cr>",
                { buffer = bufnr, desc = "Add Missing Imports" }
            )
        end
    end)
    require("typescript-tools").setup(opts)
end

return M
