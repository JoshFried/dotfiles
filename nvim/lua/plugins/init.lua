return {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    {
        "nvim-tree/nvim-web-devicons",
        dependencies = { "DaikyXendo/nvim-material-icon" },
        config = function()
            require("nvim-web-devicons").setup({
                override = require("nvim-material-icon").get_icons(),
            })
        end,
    },
    { "nacro90/numb.nvim", event = "BufReadPre", config = true },
    {
        "lukas-reineke/indent-blankline.nvim",
        event = { "BufReadPost", "BufNewFile" },
        opts = {
            indent = {
                char = "│",
                tab_char = "│",
            },
            scope = { enabled = false },
            exclude = {
                filetypes = {
                    "help",
                    "alpha",
                    "dashboard",
                    "neo-tree",
                    "Trouble",
                    "lazy",
                    "mason",
                    "notify",
                },
            },
        },
        main = "ibl",
    },
    {
        "rcarriga/nvim-notify",
        event = "VeryLazy",
        opts = {
            timeout = 3000,
            max_height = function()
                return math.floor(vim.o.lines * 0.75)
            end,
            max_width = function()
                return math.floor(vim.o.columns * 0.75)
            end,
            background_colour = "#000000",
        },
    },
    {
        "kylechui/nvim-surround",
        version = "*", -- Use for stability; omit to use `main` branch for the latest features
        event = "VeryLazy",
        config = function()
            require("nvim-surround").setup({})
        end,
    },
    {
        "numToStr/Comment.nvim",
        dependencies = { "JoosepAlviste/nvim-ts-context-commentstring" },
        keys = { "gc", "gcc", "gbc" },
        config = function(_, _)
            local opts = {
                ignore = "^$",
                pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
            }
            require("Comment").setup(opts)
        end,
    },
    {
        "mistricky/codesnap.nvim",
        build = "make",
        event = "VeryLazy",
        config = function(_, _)
            require("codesnap").setup({
                preview_title = "",
                watermark = ""
            })
        end
    },

    {
        "mfussenegger/nvim-jdtls"
    }

    -- {
    --     "zeioth/garbage-day.nvim",
    --     dependencies = "neovim/nvim-lspconfig",
    --     event = { "BufReadPost", "BufWritePost", "BufNewFile" },
    --     opts = {
    --         notifications = true,
    --     },
    -- },
}
