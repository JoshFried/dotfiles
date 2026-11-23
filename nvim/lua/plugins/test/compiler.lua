-- Load the compiler task picker and results commands on demand. Overseer supplies
-- the task execution backend.

local M = {
    "Zeioth/compiler.nvim",
    cmd = { "CompilerOpen", "CompilerToggleResults", "CompilerRedo" },
    dependencies = { "stevearc/overseer.nvim" },
    opts = {},
}

return M
