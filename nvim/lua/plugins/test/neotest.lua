local M = {
    "nvim-neotest/neotest",
    keys = {
        { "<leader>tNF", "<cmd>w|lua require('neotest').run.run({vim.fn.expand('%'), strategy = 'dap'})<cr>", desc = "Debug File" },
        { "<leader>tNL", "<cmd>w|lua require('neotest').run.run_last({strategy = 'dap'})<cr>",                desc = "Debug Last" },
        { "<leader>tNa", "<cmd>w|lua require('neotest').run.attach()<cr>",                                    desc = "Attach" },
        { "<leader>tNf", "<cmd>w|lua require('neotest').run.run(vim.fn.expand('%'))<cr>",                     desc = "File" },
        { "<leader>tNl", "<cmd>w|lua require('neotest').run.run_last()<cr>",                                  desc = "Last" },
        { "<leader>tNn", "<cmd>w|lua require('neotest').run.run()<cr>",                                       desc = "Nearest" },
        { "<leader>tNN", "<cmd>w|lua require('neotest').run.run({strategy = 'dap'})<cr>",                     desc = "Debug Nearest" },
        { "<leader>tNo", "<cmd>w|lua require('neotest').output.open({ enter = true })<cr>",                   desc = "Output" },
        { "<leader>tNs", "<cmd>w|lua require('neotest').run.stop()<cr>",                                      desc = "Stop" },
        { "<leader>tNS", "<cmd>w|lua require('neotest').summary.toggle()<cr>",                                desc = "Summary" },
    },
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-treesitter/nvim-treesitter",
        "antoinemadec/FixCursorHold.nvim",
        "nvim-neotest/neotest-vim-test",
        "vim-test/vim-test",
        "stevearc/overseer.nvim",
    },
    opts = function()
        return {
            adapters = {
                require "neotest-vim-test" {
                    ignore_file_types = { "python", "vim", "lua" },
                },
            },
            status = { virtual_text = true },
            output = { open_on_run = true },
            quickfix = {
                open = function()
                    if require("utils").has "trouble.nvim" then
                        vim.cmd "Trouble quickfix"
                    else
                        vim.cmd "copen"
                    end
                end,
            },
            -- overseer.nvim
            consumers = {
                overseer = require "neotest.consumers.overseer",
            },
            overseer = {
                enabled = true,
                force_default = true,
            },
        }
    end,
}

M.config = function(_, opts)
    local neotest_ns = vim.api.nvim_create_namespace "neotest"
    vim.diagnostic.config({
        virtual_text = {
            format = function(diagnostic)
                local message = diagnostic.message:gsub("\n", " "):gsub("\t", " "):gsub("%s+", " "):gsub("^%s+",
                    "")
                return message
            end,
        },
    }, neotest_ns)
    require("neotest").setup(opts)
end


return M
