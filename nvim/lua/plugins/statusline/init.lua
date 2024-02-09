return {
    {
        "nvim-lualine/lualine.nvim",
        event = "VeryLazy",

        config = function()
            local components = require("plugins.statusline.components")

            require("lualine").setup({
                options = {
                    icons_enabled = true,
                    theme = "auto",
                    component_separators = {},
                    section_separators = {},
                    disabled_filetypes = {
                        statusline = { "alpha", "lazy", "fugitive", "" },
                        winbar = {
                            "help",
                            "alpha",
                            "lazy",
                        },
                    },
                    always_divide_middle = true,
                    globalstatus = true,
                },
                sections = {
                    lualine_a = { { "fancy_mode", width = 3 } },
                    lualine_b = { components.git_repo, "branch" },

                    lualine_c = {
                        "filename",
                        { "fancy_cwd" },
                        components.diff,
                        { "fancy_diagnostics" }, },
                    lualine_x = {
                        components.lsp_client,
                        components.spaces,
                        "encoding",
                    },
                    lualine_y = {},
                    lualine_z = { "location" },
                },
                inactive_sections = {
                    lualine_a = {},
                    lualine_b = {},
                    -- lualine_c = { "filename", path = 2 },
                    lualine_x = { "location" },
                    lualine_y = {},
                    lualine_z = {},
                },
                extensions = { "nvim-tree", "toggleterm", "quickfix" },
            })
        end,
    },
}
