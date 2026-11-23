-- Register VenvSelect and its leader key so the current Python project can switch
-- virtual environments.

local M = {
    "linux-cultist/venv-selector.nvim",
    cmd = "VenvSelect",
    opts = {},
    keys = { { "<leader>lv", "<cmd>:VenvSelect<cr>", desc = "Select VirtualEnv" } },
}


return M
