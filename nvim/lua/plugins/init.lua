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
    },
    {
        url = "joshfri@git.amazon.com:pkg/NinjaHooks",
        branch = "mainline",
        lazy = false,
        config = function(plugin)
            vim.opt.rtp:prepend(plugin.dir .. "/configuration/vim/amazon/brazil-config")
            -- Make my own filetype thing to override neovim applying ".conf" file type.
            -- You may or may not need this depending on your setup.
            vim.filetype.add({
                filename = {
                    ['Config'] = function()
                        vim.b.brazil_package_Config = 1
                        return 'brazil-config'
                    end,
                },
            })
        end
    },
    {
        url = 'ssh://git.amazon.com/pkg/Scat-nvim',
        branch = "mainline",
        lazy = false,
        config = function()
            local scat_ok, _ = pcall(require, "scat.brazil")
            if not scat_ok then
                vim.notify("Failed to load scat.brazil", vim.log.levels.WARN)
                return
            end

            local map_key = vim.keymap.set
            local brazil = require("scat.brazil")
            local cr = require("scat.cr")
            local paste = require("scat.paste")
            local local_manager = require("scat.cr.local_manager")
            local brazil_utils = require 'scat.brazil.utils'
            local scat = require "scat"
            scat.setup {
                cr = {
                    -- template_path = vim.fn.expandcmd"$HOME/<path_to_your_cr_template>",
                    user = "joshfri" -- default user to be used when no user_id is provided to featch_active_crs
                }
            }

            map_key("n", "<leader>bl", brazil.list_all_packages, { desc = "List All Packages" })
            map_key("n", "<leader>bp", brazil.display_current_package_url, { desc = "Display Current Package URL" })
            map_key("n", "<leader>bP", brazil.display_package_under_cursor_url,
                { desc = "Display URL for Package under Cursor" })
            map_key("n", "<leader>bR", brazil.display_release_under_cursor_url,
                { desc = "Display URL for Release under Cursor" })
            map_key({ "n", "x" }, "<leader>bf", brazil.display_current_file_url, { desc = "Display Current File URL" })
            map_key("n", "<leader>bij", brazil.install_current_jdt_package, { desc = "Install Current JDT Package" })
            map_key("n", "<leader>br", cr.open_cr, { desc = "Open CR" })
            -- or map_key("n", "<leader>br", function() cr.open_cr({ cr_template = vim.fn.expandcmd"$HOME/<path_to_your_cr_template>" }) end, { desc = "Open CR" })
            map_key("n", "<leader>brp", cr.fetch_active_crs, { desc = "Fetch Active CRs" })
            -- the below mapping prompts for user id you would like to view instead of picking from config
            map_key("n", "<leader>brpp", function() cr.fetch_active_crs({ force_pick = true }) end,
                { desc = "Fetch Active CRs (ignore user specified in config)" })
            -- or map_key("n", "<leader>brp", function() cr.fetch_active_crs({user = "<your_user_name>"}) end)
            map_key("n", "<leader>bru", cr.update_existing_cr, { desc = "Update Existing CR" })
            map_key("n", "<leader>brt", local_manager.toggle_cr_overview, { desc = "Toggle CR Overview" })
            map_key("n", "<leader>bc", brazil_utils.run_checkstyle, { desc = "Run Brazil Checkstyle" })
            map_key('n', '<leader>bb', brazil.build_current_package, { desc = "Build Current Package" })
            map_key('n', '<leader>bbc', brazil.run_command_inside_current_package,
                { desc = "Run Brazil Command inside Current Package" })
            map_key("n", "<leader>bbt", function()
                brazil.pick_brazil_task_inside_current_package({
                    callback = function(task)
                        vim.g.test_replacement_command = task
                    end,
                })
            end, { desc = "Pick Brazil Task inside Current Package" })
            map_key('n', '<leader>bbl', brazil.run_prev_brazil_task, { desc = "Run Previous Brazil Task" })
            map_key('n', '<leader>bv', brazil.display_current_version_set_url,
                { desc = "Display Current Version Set URL" })
            map_key('n', '<leader>bbr', brazil.build_current_package_recursively,
                { desc = "Build Current Package Recursively" })
            map_key('n', '<leader>bw', brazil.switch_workspace_package_info,
                { desc = "Switch packageInfo in Current Workspace" })
            map_key({ 'n', 'x' }, '<leader>bs', paste.send_to_pastebin, { desc = "Send Selection to Pastebin" })
            map_key('n', '<leader>bsl', paste.list_my_pastes, { desc = "List My Pastes" })
            -- if you are using the patched fork of Telescope, you can also leverage these, see more details below
            -- map_key('n', '<leader>bis', brazil.lookup_packages, { desc = "Lookup Packages" })
            -- map_key('n', '<leader>biv', brazil.lookup_version_set, { desc = "Lookup Version Set" })
        end,
        requires = { "nvim-telescope/telescope.nvim", "sindrets/diffview.nvim" },
    },
    -- {
    --     'nvim-java/nvim-java',
    --     config = false,
    --     dependencies = {
    --         {
    --             'neovim/nvim-lspconfig',
    --             opts = {
    --                 servers = {
    --                     jdtls = {
    --                         -- Your custom jdtls settings goes here
    --                     },
    --                 },
    --                 setup = {
    --                     jdtls = function()
    --                         require('java').setup({
    --                             -- Your custom nvim-java configuration goes here
    --                         })
    --                     end,
    --                 },
    --             },
    --         },
    --     },
    -- }


    -- plugins.lua
    -- {
    --     name = 'amazonq',
    --     url = 'ssh://git.amazon.com/pkg/AmazonQNVim',
    --     lazy = false,
    --     opts = {
    --         ssoStartUrl = 'https://amzn.awsapps.com/start',
    --         ft = {
    --             "amazonq",
    --             "java",
    --             "python",
    --             "typescript",
    --             "javascript",
    --             "csharp",
    --             "ruby",
    --             "kotlin",
    --             "shell",
    --             "sql",
    --             "c",
    --             "cpp",
    --             "go",
    --             "rust",
    --             "lua",
    --         },
    --         inline_suggest = true,
    --         -- Note: It's normally not necessary to change default `lsp_server_cmd`.
    --         -- lsp_server_cmd = {
    --         --   'node',
    --         --   vim.fn.stdpath('data') .. '/lazy/AmazonQNVim/language-server/build/aws-lsp-codewhisperer-token-binary.js',
    --         --   '--stdio',
    --         -- },
    --     },
    -- },
    -- {
    --     "mfussenegger/nvim-jdtls",
    -- },
}
