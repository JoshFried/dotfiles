local M = {
    -- "mfussenegger/nvim-dap",
    -- opts = {
    --     setup = {
    --         codelldb = function()
    --             local codelldb_path, _ = Get_codelldb()
    --             local dap = require("dap")
    --             dap.adapters.codelldb = {
    --                 type = "server",
    --                 port = "${port}",
    --                 executable = {
    --                     command = codelldb_path,
    --                     args = { "--port", "${port}" },
    --                 },
    --             }
    --             dap.configurations.cpp = {
    --                 {
    --                     name = "Launch file",
    --                     type = "codelldb",
    --                     request = "launch",
    --                     program = function()
    --                         return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
    --                     end,
    --                     cwd = "${workspaceFolder}",
    --                     stopOnEntry = false,
    --                 },
    --             }

    --             dap.configurations.c = dap.configurations.cpp
    --             dap.configurations.rust = dap.configurations.cpp
    --         end,
    --     },
    -- }
}

return M
