return {
    "saecki/Crates.nvim",
    event = { "BufRead Cargo.toml" },
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
        popup = { border = "rounded" },
        completion = {
            crates = { enabled = true, max_results = 8, min_chars = 3 },
        },
        lsp = {
            enabled = true,
            completion = true,
        },
    },
    config = function(_, opts)
        local crates = require("crates")
        crates.setup(opts)

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
