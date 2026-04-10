local M = {}

M.autoformat = true

function M.toggle()
    M.autoformat = not M.autoformat
    vim.notify(M.autoformat and "Enabled format on save" or "Disabled format on save")
end

function M.format()
    require("conform").format({ async = true, lsp_format = "fallback" })
end

return M
