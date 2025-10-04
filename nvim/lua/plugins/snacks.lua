return {
    {
        "folke/snacks.nvim",
        ---@type snacks.Config.base
        opts = {
            ---@type snacks.gitbrowse.Config
            ---@diagnostic disable-next-line: missing-fields
            gitbrowse = {
                url_patterns = {
                    ["code.amazon.com"] = {
                        branch = "trees/{branch}",
                        file = "/blobs/{branch}/--/{file}#L{line_start}-L{line_end}",
                        permalink = "/blobs/{commit}/--/{file}#L{line_start}-L{line_end}",
                        commit = "/commits/{commit}",
                    },
                },

                remote_patterns = {
                    -- Amazon specific pattern
                    { "^ssh://git.amazon.com:2222/pkg/(.+)$",   "https://code.amazon.com/packages/%1" },
                    { "^https://git.amazon.com:2222/pkg/(.+)$", "https://code.amazon.com/packages/%1" },

                    -- Original patterns
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
