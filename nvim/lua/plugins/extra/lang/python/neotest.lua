local M = {
    "nvim-neotest/neotest",
    dependencies = {
        "nvim-neotest/neotest-python",
    },
    opts = function(_, opts)
        vim.list_extend(opts.adapters, {
            require "neotest-python" {
                dap = { justmycode = false },
                runner = "unittest",
            },
        })
    end,
}

return M
