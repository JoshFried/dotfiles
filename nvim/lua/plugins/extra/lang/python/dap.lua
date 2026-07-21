local M = {
    "mfussenegger/nvim-dap",
    dependencies = {
        {
            -- config lives on nvim-dap-python itself: putting a `config` on the
            -- shared nvim-dap spec would REPLACE dap/init.lua's config
            -- (dapui listeners, virtual text) due to lazy.nvim last-wins merging.
            "mfussenegger/nvim-dap-python",
            config = function()
                local path = vim.fn.expand("$MASON/packages/debugpy")
                require("dap-python").setup(path .. "/venv/bin/python")
            end,
        },
    },
}

return M
