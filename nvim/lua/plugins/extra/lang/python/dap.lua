local M = {
    "mfussenegger/nvim-dap",
    dependencies = {
        "mfussenegger/nvim-dap-python",
    },
}


M.config = function()
    local path = vim.fn.expand("$MASON/packages/debugpy")
    require("dap-python").setup(path .. "/venv/bin/python")
end

return M
