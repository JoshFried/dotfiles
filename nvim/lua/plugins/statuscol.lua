return {
    {
        "luukvbaal/statuscol.nvim",
        lazy = false,
        config = function(opts)
            local builtin = require("statuscol.builtin")
            require("statuscol").setup({
                relculright = true,
                segments = {
                    { text = { builtin.foldfunc },      click = "v:lua.ScFa" },
                    { text = { "%s" },                  click = "v:lua.ScSa" },
                    { text = { builtin.lnumfunc, " " }, click = "v:lua.ScLa" },
                    {
                        sign = { name = { "Diagnostic" }, maxwidth = 2, auto = true, click = "v:lua.ScLa" },
                    },
                },
            })
        end,
    },
}
