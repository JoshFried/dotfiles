local M = {
    "saecki/Crates.nvim",
    event = { "BufRead Cargo.toml" },
    null_ls = {
        enabled = true,
        name = "crates.nvim",
    },
    dependencies = { "nvim-lua/plenary.nvim" },
}

M.config = function()
    local ok, crates = pcall(require, "crates")
    if not ok then 
        vim.notify("Failed to load crates.nvim", vim.log.levels.ERROR)
        return 
    end
    
    crates.setup({
        popup = {
            border = "rounded",
        },
        completion = {
            crates = {
                enabled = true,
                max_results = 8,
                min_chars = 3,
            }
        }
    })
end


return M
