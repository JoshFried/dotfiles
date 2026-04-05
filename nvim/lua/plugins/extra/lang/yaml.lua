return {
    {
        "nvim-treesitter/nvim-treesitter",
        opts = function()
            require("nvim-treesitter").install({ "yaml" })
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
