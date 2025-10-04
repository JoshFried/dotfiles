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
                        {
                            "filename",
                            path = 1,
                            symbols = {
                                modified = " ●",
                                readonly = " ",
                                unnamed = "[No Name]",
                            },
                        },
                        { "fancy_cwd", substitute_home = true },
                        components.diff,
                        { "fancy_diagnostics" },
                        {
                            function()
                                if vim.v.hlsearch == 0 then return "" end
                                local ok, result = pcall(vim.fn.searchcount, { maxcount = 999, timeout = 500 })
                                if not ok or next(result) == nil then return "" end
                                local denominator = math.min(result.total, result.maxcount)
                                return string.format("[%d/%d]", result.current, denominator)
                            end,
                        },
                        components.noice_command,
                        components.noice_mode,
                    },
                    lualine_x = {
                        {
                            function()
                                local recording_register = vim.fn.reg_recording()
                                if recording_register == "" then return "" end
                                return "Recording @" .. recording_register
                            end,
                            color = { fg = "#ff9e64" },
                        },
                        components.lsp_client,
                        components.spaces,
                        "encoding",
                    },
                    lualine_y = {
                        {
                            function()
                                return "Buf:" .. #vim.fn.getbufinfo({buflisted = 1})
                            end,
                        },
                    },
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
