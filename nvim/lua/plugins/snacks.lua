return {
    {
        "folke/snacks.nvim",
        priority = 1000,
        lazy = false,
        keys = {
            { "<leader>go", function() require("snacks").gitbrowse() end, desc = "Open in browser", mode = { "n", "x" } },
            { "<leader>gy", function() require("snacks").gitbrowse({ open = function(url) vim.fn.setreg("+", url) vim.notify("Copied: " .. url) end }) end, desc = "Copy git URL", mode = { "n", "x" } },
            { "<leader>cR", function() require("snacks").rename.rename_file() end, desc = "Rename File" },
            { "<leader>nh", function() require("snacks").notifier.show_history() end, desc = "Notification History" },
            { "<leader>nd", function() require("snacks").notifier.hide() end, desc = "Dismiss Notifications" },
            { "]r", function() require("snacks").words.jump(vim.v.count1) end, desc = "Next Reference" },
            { "[r", function() require("snacks").words.jump(-vim.v.count1) end, desc = "Prev Reference" },
        },
        ---@type snacks.Config
        opts = {
            bigfile = { enabled = true },
            quickfile = { enabled = true },
            words = { enabled = true },
            indent = { enabled = true },
            notifier = { enabled = true, timeout = 3000 },
            toggle = {},
            rename = { enabled = true },
            ---@type snacks.gitbrowse.Config
            ---@diagnostic disable-next-line: missing-fields
            gitbrowse = {
                remote_patterns = {
                    { "^(https?://.*)%.git$",                   "%1" },
                    { "^git@(.+):(.+)%.git$",                   "https://%1/%2" },
                    { "^git@(.+):(.+)$",                        "https://%1/%2" },
                    { "^git@(.+)/(.+)$",                        "https://%1/%2" },
                    { "^org%-%d+@(.+):(.+)%.git$",              "https://%1/%2" },
                    { "^ssh://git@(.*)$",                       "https://%1" },
                    { "^ssh://([^:/]+)(:%d+)/(.*)$",            "https://%1/%3" },
                    { "^ssh://([^/]+)/(.*)$",                   "https://%1/%2" },
                    { "ssh%.dev%.azure%.com/v3/(.*)/(.*)$",     "dev.azure.com/%1/_git/%2" },
                    { "^https://%w*@(.*)",                      "https://%1" },
                    { "^git@(.*)",                              "https://%1" },
                    { ":%d+",                                   "" },
                    { "%.git$",                                 "" },
                },
            },
        },
    }
}
