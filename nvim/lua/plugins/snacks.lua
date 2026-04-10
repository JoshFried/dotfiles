return {
    {
        "folke/snacks.nvim",
        ---@type snacks.Config.base
        opts = {
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
