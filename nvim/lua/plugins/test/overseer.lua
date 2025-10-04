local M = {
    "stevearc/overseer.nvim",
    keys = {
        { "<leader>toR", "<cmd>OverseerRunCmd<cr>",       desc = "Run Command" },
        { "<leader>toa", "<cmd>OverseerTaskAction<cr>",   desc = "Task Action" },
        { "<leader>tob", "<cmd>OverseerBuild<cr>",        desc = "Build" },
        { "<leader>toc", "<cmd>OverseerClose<cr>",        desc = "Close" },
        { "<leader>tod", "<cmd>OverseerDeleteBundle<cr>", desc = "Delete Bundle" },
        { "<leader>tol", "<cmd>OverseerLoadBundle<cr>",   desc = "Load Bundle" },
        { "<leader>too", "<cmd>OverseerOpen<cr>",         desc = "Open" },
        { "<leader>tOr", "<cmd>OverseerOpen Right<cr>",   desc = "Open" },
        { "<leader>toq", "<cmd>OverseerQuickAction<cr>",  desc = "Quick Action" },
        { "<leader>tor", "<cmd>OverseerRun<cr>",          desc = "Run" },
        { "<leader>tos", "<cmd>OverseerSaveBundle<cr>",   desc = "Save Bundle" },
        { "<leader>tot", "<cmd>OverseerToggle<cr>",       desc = "Toggle" },
    },
    bindings = { ["q"] = function() vim.cmd("OverseerClose") end },
    config = true,
    component_aliases = {
        default = {
            "on_exit_set_status",
            "on_complete_notify",
            "open_output"
        },
    },
}

return M
