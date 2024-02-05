local M = {
    "mfussenegger/nvim-dap",
    dependencies = {
        "mfussenegger/nvim-dap-python",
    },
}


M.config = function()
    local path = require("mason-registry").get_package("debugpy"):get_install_path()
    require("dap-python").setup(path .. "/venv/bin/python")
end

return M
