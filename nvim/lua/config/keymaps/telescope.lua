-- Telescope keymaps
return {
    { "<leader>sf", function() require("telescope.builtin").find_files() end, desc = "Find Files" },
    { "<leader>sd", function() require("telescope.builtin").diagnostics() end, desc = "Search Diagnostics" },
    { "<leader>tkm", function() require("telescope.builtin").keymaps() end, desc = "Keymaps" },
    { "<leader>zc", function() require("telescope.builtin").colorscheme({ enable_preview = true }) end, desc = "Colorscheme" },
    { "<leader>?", "<cmd>Telescope oldfiles<cr>", desc = "Recent Files" },
    { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
    { "<leader>ps", "<cmd>Telescope repo list<cr>", desc = "Search Repos" },
    { "<leader>hs", "<cmd>Telescope help_tags<cr>", desc = "Help Tags" },
    { "<leader>tgs", "<cmd>Telescope git_status<cr>", desc = "Git Status" },
    { "<leader>tgb", "<cmd>Telescope git_branches<cr>", desc = "Git Branches" },
    { "<leader>tgc", "<cmd>Telescope git_commits<cr>", desc = "Git Commits" },
    { "<leader>tags", "<cmd>AdvancedGitSearch<cr>", desc = "Advanced Git Search" },
    { "<leader>sg", "<cmd>Telescope live_grep<cr>", desc = "Live Grep" },
    { "<leader>sb", function() require("telescope.builtin").current_buffer_fuzzy_find() end, desc = "Buffer Search" },
    { "<leader>sk", function() require("telescope.builtin").keymaps() end, desc = "Search Keymaps" },
    { "<leader>sj", function() require("telescope.builtin").jumplist() end, desc = "Search Jumplist" },
    { "<leader>sc", function() require("telescope.builtin").commands() end, desc = "Search Commands" },
    { "<leader>pp", function() require("telescope").extensions.project.project({ display_type = "minimal" }) end, desc = "Projects" },
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
        desc = "Fuzzy search in buffer" 
    },
}
