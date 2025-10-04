return {
    {
        "rebelot/kanagawa.nvim",
        name = "kanagawa",
        lazy = false,
        enable = true,
        priority = 1000,
        build = "KanagawaCompile",
        config = function()
            local ok, theme = pcall(require, "kanagawa")
            if not ok then 
                vim.notify("Failed to load kanagawa theme", vim.log.levels.ERROR)
                return 
            end
            
            theme.setup({
                compile = true,
                transparent = true,
                commentStyle = { italic = false },
                keywordStyle = { italic = false },
                terminalColors = true,
                colors = {
                    theme = {
                        all = {
                            ui = {
                                bg_gutter = "none",
                            },
                        },
                    },
                },
                overrides = function(colors)
                    local colours = colors.theme
                    return {
                        FloatBoarder = { bg = "none" },
                        FloatTitle = { bg = "none" },
                        NormalFloat = { bg = "none" },

                        LazyNormal = { fg = colours.ui.fg_dim, bg = colours.ui.bg_m3 },
                        MasonNormal = { fg = colours.ui.fg_dim, bg = colours.ui.bg_m3 },

                        TelescopeTitle = { fg = colours.ui.special, bold = true },
                        TelescopePromptNormal = { bg = colours.ui.bg_p1 },
                        TelescopePromptBorder = { bg = colours.ui.bg_p1, fg = colours.ui.bg_p1 },
                        TelescopeResultsNormal = { bg = colours.ui.bg_m1, fg = colours.ui.fg_dim },
                        TelescopeResultsBorder = { bg = colours.ui.bg_m1, fg = colours.ui.bg_m1 },
                        TelescopePreviewNormal = { bg = colours.ui.db_dim },
                        TelescopePreviewBorder = { bg = colours.ui.bg_dim, fg = colours.ui.bg_dim },

                        Pmenue = { fb = colours.ui.shade0, bg = colours.ui.bg_p1 },
                        PmenuSel = { fg = "none", bg = colours.ui.bg_p2 },
                        PmenuSbar = { bg = colours.ui.bg_m1 },
                        PmenuThumb = { bg = colours.ui.bg_p2 },

                        LspInlayHint = { bg = "none", fg = "#7f7f7f" },
                    }
                end,
            })

            vim.cmd.colorscheme("kanagawa")
        end,
    },
}
