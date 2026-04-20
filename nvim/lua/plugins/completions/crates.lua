return {
    "saecki/Crates.nvim",
    event = { "BufRead Cargo.toml" },
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
        popup = { border = "rounded" },
        completion = {
            crates = { enabled = true, max_results = 8, min_chars = 3 },
        },
    },
    config = function(_, opts)
        local crates = require("crates")
        crates.setup(opts)

        -- Register crates' nvim-cmp source under blink.compat's shim so blink
        -- can surface completions via the `crates` provider in blink.lua.
        pcall(function()
            require("crates.completion.cmp").setup()
        end)

        vim.api.nvim_create_autocmd("BufRead", {
            pattern = "Cargo.toml",
            callback = function(ev)
                vim.keymap.set("n", "K", function()
                    if crates.popup_available() then
                        crates.show_popup()
                    else
                        vim.lsp.buf.hover()
                    end
                end, { buffer = ev.buf, desc = "Crates popup / Hover" })
            end,
        })
    end,
}
