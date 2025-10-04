return {
    {
        "nvim-telescope/telescope.nvim",
        dependencies = {
            { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
            "nvim-telescope/telescope-ui-select.nvim",
            "nvim-telescope/telescope-project.nvim",
            "ahmedkhalf/project.nvim",
            "aaronhallaert/advanced-git-search.nvim",
            "cljoly/telescope-repo.nvim",
        },
        cmd = "Telescope",
        keys = {
            {
                "<leader>sf",
                function()
                    require("telescope.builtin").find_files()
                end,
                desc = "[F]ind [F]iles",
            },
            {
                "<leader>sd",
                function()
                    require("telescope.builtin").diagnostics()
                end,
                desc = "[S]earch [D]iagnostics",
            },
            {
                "<leader>tkm",
                function()
                    require("telescope.builtin").keymaps()
                end,
                desc = "Keymaps",
            },
            {
                "<leader>zc",
                function()
                    require("telescope.builtin").colorscheme({ enable_preview = true })
                end,
                desc = "Colorscheme",
            },
            { "<leader>?",    "<cmd>Telescope oldfiles<cr>",     desc = "Recent" },
            { "<leader>fb",   "<cmd>Telescope buffers<cr>",      desc = "Buffers" },
            { "<leader>ps",   "<cmd>Telescope repo list<cr>",    desc = "Search" },
            { "<leader>hs",   "<cmd>Telescope help_tags<cr>",    desc = "Search" },
            { "<leader>tgs",  "<cmd>Telescope git_status<cr>",   desc = "telescope git status" },
            { "<leader>tgb",  "<cmd>Telescope git_branches<cr>", desc = "telescope git status" },
            { "<leader>tgc",  "<cmd>Telescope git_commits<cr>",  desc = "telescope git status" },
            { "<leader>tags", "<cmd>AdvancedGitSearch<cr>",      desc = "telescope git status" },
            {
                "<leader>/",
                function()
                    require("telescope.builtin").current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
                        winblend = 10,
                        previewer = false,
                        layout_config = {
                            width = function(_, max_columns, _)
                                return math.min(max_columns, 150)
                            end,
                        },
                    }))
                end,
                { desc = "[/] Fuzzily search in current buffer" },
            },
            {
                "<leader>pp",
                function()
                    require("telescope").extensions.project.project({
                        display_type = "minimal",
                    })
                end,
                desc = "List",
            },
            {
                "<leader>sg",
                "<cmd>Telescope live_grep<cr>",
                desc =
                "Workspace"
            },
            {
                "<leader>sb",
                function()
                    require("telescope.builtin").current_buffer_fuzzy_find()
                end,
                desc = "Buffer",
            },
            {
                "<leader>sk",
                function()
                    require("telescope.builtin").keymaps()
                end,
                desc = "Search Keymaps"
            },
            {
                "<leader>sj",
                function()
                    require("telescope.builtin").jumplist()
                end,
                desc = "Search Keymaps"
            },
            {
                "<leader>sc",
                function()
                    require("telescope.builtin").commands()
                end,
                desc = "Search Commands"
            }
        },
        config = function(_, _)
            local ok, telescope = pcall(require, "telescope")
            if not ok then 
                vim.notify("Failed to load telescope", vim.log.levels.ERROR)
                return 
            end
            
            local icons = require("config.icons")
            local actions = require("telescope.actions")
            local actions_layout = require("telescope.actions.layout")
            local action_state = require("telescope.actions.state")


            local mappings = {
                i = {
                    ["<C-j>"] = actions.move_selection_next,
                    ["<C-k>"] = actions.move_selection_previous,
                    ["<C-n>"] = actions.cycle_history_next,
                    ["<C-p>"] = actions.cycle_history_prev,
                    ["<A-p>"] = actions_layout.toggle_preview,
                    ["<C-h>"] = actions.select_horizontal,
                    ["<C-v>"] = actions.select_vertical,
                    ["<A-m>"] = actions_layout.toggle_mirror,
                    -- ["<C-r>"] = custom_actions.file_browser,
                },
            }

            local opts = {
                defaults = {
                    prompt_prefix = icons.ui.Telescope .. " ",
                    selection_caret = icons.ui.Forward .. " ",
                    mappings = mappings,
                    border = {},
                    borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
                    color_devicons = true,
                },
                pickers = {
                    find_files = {
                        theme = "dropdown",
                        previewer = false,
                        hidden = true,
                        find_command = { "rg", "--files", "--hidden", "-g", "!.git" },
                    },
                    git_files = {
                        theme = "dropdown",
                        previewer = false,
                    },
                    buffers = {
                        theme           = "dropdown",
                        previewer       = false,
                        attach_mappings = function(prompt_bufnr, map)
                            local delete_buf = function()
                                local selection = action_state.get_selected_entry()
                                actions.close(prompt_bufnr)
                                vim.api.nvim_buf_delete(selection.bufnr, { force = true })
                            end

                            -- mode, key, func
                            -- this is just an example
                            map('n', 'd', delete_buf)
                            map('i', '<c-d>', delete_buf)
                            return true
                        end
                    },
                },
                extensions = {
                    project = {
                        hidden_files = false,
                        theme = "dropdown",
                    },
                    fzy_native = {
                        override_generic_sorter = true,
                        override_file_sorter = true,
                    },
                    fzf_writer = {
                        use_highlighter = false,
                        minimum_grep_characters = 6,
                    },
                    ["ui-select"] = {
                        -- this makes it so RustDebuggables are readable without needing to wrap text
                        require("telescope.themes").get_dropdown({
                            layout_config = {
                                width = function(_, max_columns, _)
                                    return math.min(max_columns, 150)
                                end,
                            },
                        }),
                    },
                },
            }
            telescope.setup(opts)
            telescope.load_extension("fzf")
            telescope.load_extension("project")
            telescope.load_extension("projects")
            telescope.load_extension("ui-select")
            telescope.load_extension("advanced_git_search")
        end,
    },
    {
        "ahmedkhalf/project.nvim",
        config = function()
            require("project_nvim").setup({
                detection_methods = { "pattern", "lsp" },
                patterns = { ".git" },
                ignore_lsp = { "null-ls" },
            })
        end,
    },
}
