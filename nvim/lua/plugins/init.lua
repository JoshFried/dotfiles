return {
    { "nvim-lua/plenary.nvim", lazy = true },
    { "MunifTanjim/nui.nvim",  lazy = true },
    {
        "nvim-tree/nvim-web-devicons",
        dependencies = { "DaikyXendo/nvim-material-icon" },
        config = function()
            local ok, icons = pcall(require, "nvim-web-devicons")
            if not ok then
                vim.notify("Failed to load nvim-web-devicons", vim.log.levels.ERROR)
                return
            end

            icons.setup({
                -- override = require("nvim-material-icon").get_icons(),
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
                    -- "help",
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
            local ok, surround = pcall(require, "nvim-surround")
            if not ok then 
                vim.notify("Failed to load nvim-surround", vim.log.levels.ERROR)
                return 
            end
            
            surround.setup({})
        end,
    },
    {
        "numToStr/Comment.nvim",
        dependencies = { "JoosepAlviste/nvim-ts-context-commentstring" },
        keys = { "gc", "gcc", "gbc" },
        config = function(_, _)
            local comment_ok, comment = pcall(require, "Comment")
            if not comment_ok then 
                vim.notify("Failed to load Comment.nvim", vim.log.levels.ERROR)
                return 
            end
            
            local opts = {
                ignore = "^$",
                pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
            }
            comment.setup(opts)
        end,
    },
    {
        "mistricky/codesnap.nvim",
        build = "make",
        event = "VeryLazy",
        config = function(_, _)
            local ok, codesnap = pcall(require, "codesnap")
            if not ok then
                vim.notify("Failed to load codesnap.nvim", vim.log.levels.ERROR)
                return
            end

            codesnap.setup({
                preview_title = "",
                watermark = ""
            })
        end
    }
}
