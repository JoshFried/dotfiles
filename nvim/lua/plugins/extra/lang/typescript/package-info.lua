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

        -- Apply keymaps on BufEnter so they survive jsonls' LspAttach which
        -- would otherwise overwrite K.
        vim.api.nvim_create_autocmd("BufEnter", {
            pattern = "package.json",
            callback = function(ev)
                local pi = require("package-info")
                local map = function(lhs, rhs, desc)
                    vim.keymap.set("n", lhs, rhs, { buffer = ev.buf, desc = desc, silent = true })
                end

                -- Hover on current dependency
                map("K", function() pi.show({ force = true }) end, "Package info (hover)")

                -- Virtual text toggles
                map("<leader>Ps", pi.show, "Show versions")
                map("<leader>Ph", pi.hide, "Hide versions")
                map("<leader>Pt", pi.toggle, "Toggle versions")

                -- Dependency lifecycle
                map("<leader>Pi", pi.install, "Install new")
                map("<leader>Pu", pi.update, "Update to latest")
                map("<leader>Pd", pi.delete, "Delete")
                map("<leader>Pv", pi.change_version, "Change version")
            end,
        })
    end,
}
