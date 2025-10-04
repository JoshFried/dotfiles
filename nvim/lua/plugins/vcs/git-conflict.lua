local M = {
    "akinsho/git-conflict.nvim",
    --stylua: ignore
    keys = {
        -- { "<leader>gC", function() require("plugins.vcs.hydra").open_git_conflict_hydra() end, desc = "Conflict" },
        -- { "<leader>gS", function() require("plugins.vcs.hydra").open_git_signs_hydra() end,    desc = "Signs" },
    },
    cmd = {
        "GitConflictChooseBoth",
        "GitConflictNextConflict",
        "GitConflictChooseOurs",
        "GitConflictPrevConflict",
        "GitConflictChooseTheirs",
        "GitConflictListQf",
        "GitConflictChooseNone",
        "GitConflictRefresh",
    },
    opts = {
        default_mappings = true,
        default_commands = true,
        disable_diagnostics = true,
    },
}

return M
