return {
    "vuki656/package-info.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    event = { "BufRead package.json" },
    opts = {
        hide_up_to_date = true,
        icons = { enable = true },
    },
    config = function(_, opts)
        require("package-info").setup(opts)

        -- Override K on package.json buffers. Re-apply on BufEnter because
        -- jsonls' LspAttach runs after BufRead and would otherwise win.
        vim.api.nvim_create_autocmd("BufEnter", {
            pattern = "package.json",
            callback = function(ev)
                local pi = require("package-info")
                local map = function(lhs, rhs, desc)
                    vim.keymap.set("n", lhs, rhs, { buffer = ev.buf, desc = desc })
                end
                map("K", function() pi.show({ force = true }) end, "Package info")
                map("<leader>pu", pi.update, "Update package")
                map("<leader>pd", pi.delete, "Delete package")
                map("<leader>pc", pi.change_version, "Change package version")
            end,
        })
    end,
}
