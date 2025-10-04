return {
    {
        "nvim-treesitter/nvim-treesitter",
        opts = function(_, opts)
            if type(opts.ensure_installed) == "table" then
                vim.list_extend(opts.ensure_installed, { "yaml" })
            end
        end,
    },
    {
        "neovim/nvim-lspconfig",
        opts = {
            -- make sure mason installs the server
            servers = {
                yamlls = {
                    settings = {
                        -- redhat = { telemetry = { enabled = false } },
                        yaml = {
                            keyOrdering = false,
                            format = {
                                enable = true,
                            },
                            hover = true,
                            completion = true,
                            customTags = {
                                "!fn",
                                "!And",
                                "!If",
                                "!Not",
                                "!Equals",
                                "!Or",
                                "!FindInMap sequence",
                                "!Base64",
                                "!Cidr",
                                "!Ref",
                                "!Ref Scalar",
                                "!Sub",
                                "!GetAtt",
                                "!GetAZs",
                                "!ImportValue",
                                "!Select",
                                "!Split",
                                "!Join sequence"
                            },
                            validate = { enable = true },
                        },
                    },
                },
            },
        },
    },
}
