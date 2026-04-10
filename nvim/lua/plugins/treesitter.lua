return {
    {
        "nvim-treesitter/nvim-treesitter",
        branch = "main",
        dependencies = {
            { "nvim-treesitter/nvim-treesitter-textobjects", branch = "main" },
            "JoosepAlviste/nvim-ts-context-commentstring",
            "nvim-treesitter/nvim-treesitter-context",
        },
        build = ":TSUpdate",
        event = "BufReadPost",
        config = function()
            require("nvim-treesitter").setup()

            local ensure_installed = {
                "bash", "dockerfile", "html", "kotlin", "lua",
                "markdown", "markdown_inline", "query", "regex",
                "vim", "yaml", "typescript", "tsx", "javascript", "css",
            }
            vim.defer_fn(function()
                local installed = require("nvim-treesitter.config").get_installed()
                local to_install = vim.tbl_filter(function(p)
                    return not vim.tbl_contains(installed, p)
                end, ensure_installed)
                if #to_install > 0 then
                    require("nvim-treesitter").install(to_install)
                end
            end, 0)

            -- Highlighting and indentation
            vim.api.nvim_create_autocmd("FileType", {
                callback = function()
                    pcall(vim.treesitter.start)
                    local has_indent = #vim.treesitter.query.get_files(vim.bo.filetype, "indents") > 0
                    if has_indent then
                        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
                    end
                end,
            })

            -- Textobjects config (non-keymap options)
            require("nvim-treesitter-textobjects").setup({
                select = { lookahead = true },
                move = { set_jumps = true },
            })

            -- Textobjects: select keymaps
            local select_maps = {
                ["ab"] = "@block.outer",    ["ib"] = "@block.inner",
                ["ap"] = "@parameter.outer", ["ip"] = "@parameter.inner",
                ["af"] = "@function.outer",  ["if"] = "@function.inner",
                ["ac"] = "@class.outer",     ["ic"] = "@class.inner",
                ["al"] = "@loop.outer",      ["il"] = "@loop.inner",
                ["ai"] = "@conditional.outer", ["ii"] = "@conditional.inner",
            }
            for key, query in pairs(select_maps) do
                vim.keymap.set({ "x", "o" }, key, function()
                    require("nvim-treesitter-textobjects.select").select_textobject(query, "textobjects")
                end)
            end

            -- Textobjects: move keymaps
            local move_fns = {
                ["]m"] = { "goto_next_start", "@function.outer" },
                ["]]"] = { "goto_next_start", "@class.outer" },
                ["[p"] = { "goto_next_start", "@parameter.inner" },
                ["]M"] = { "goto_next_end", "@function.outer" },
                ["]["] = { "goto_next_end", "@class.outer" },
                ["[m"] = { "goto_previous_start", "@function.outer" },
                ["[["] = { "goto_previous_start", "@class.outer" },
                ["]p"] = { "goto_previous_start", "@parameter.inner" },
                ["[M"] = { "goto_previous_end", "@function.outer" },
                ["[]"] = { "goto_previous_end", "@class.outer" },
            }
            for key, spec in pairs(move_fns) do
                vim.keymap.set({ "n", "x", "o" }, key, function()
                    require("nvim-treesitter-textobjects.move")[spec[1]](spec[2], "textobjects")
                end)
            end

            -- Textobjects: swap keymaps
            local swap_objects = { p = "@parameter.inner", f = "@function.outer", c = "@class.outer" }
            for key, query in pairs(swap_objects) do
                vim.keymap.set("n", "<leader>cx" .. key, function()
                    require("nvim-treesitter-textobjects.swap").swap_next(query, "textobjects")
                end)
                vim.keymap.set("n", "<leader>cX" .. key, function()
                    require("nvim-treesitter-textobjects.swap").swap_previous(query, "textobjects")
                end)
            end

            -- ts_context_commentstring
            local ok, ts_ctx = pcall(require, "ts_context_commentstring")
            if ok then ts_ctx.setup({}) end
        end,
    },
}
