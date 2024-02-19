local M = {
    "pmizio/typescript-tools.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "neovim/nvim-lspconfig",
        { "folke/neoconf.nvim", cmd = "Neoconf", config = true }
    },
    ft = {
        "typescript", "typescriptreact", "javascript", "javascriptreact"
    },
    opts = {
        separate_diagnostic_server = true,
        expose_as_code_action = "all",
        -- tsserver_plugins = {},
        tsserver_max_memory = "auto",
        complete_function_calls = true,
        include_completions_with_insert_text = true,
        tsserver_file_preferences = {
            includeInlayParameterNameHints = "all",
            includeInlayParameterNameHintsWhenArgumentMatchesName = true,
            includeInlayFunctionParameterTypeHints = true,
            includeInlayVariableTypeHints = true,
            includeInlayVariableTypeHintsWhenTypeMatchesName = true,
            includeInlayPropertyDeclarationTypeHints = true,
            includeInlayFunctionLikeReturnTypeHints = true,
            includeInlayEnumMemberValueHints = true,
            includeCompletionsForModuleExports = true,
            quotePreference = "auto",
        },
    },
}

M.config = function(_, opts)
    require("plugins.lsp.utils").on_attach(function(client, bufnr)
        -- if client.name == "tsserver" then
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

        -- end
    end)
    require("typescript-tools").setup({})
end

return M
