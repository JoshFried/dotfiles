local icons = require("config.icons")

local function fg(name)
    return function()
        local hl = vim.api.nvim_get_hl(0, { name = name })
        return hl and hl.fg and { fg = string.format("#%06x", hl.fg) }
    end
end

return {
    spaces = {
        function()
            return icons.ui.Tab .. " " .. vim.bo[0].shiftwidth
        end,
        padding = 1,
    },
    git_repo = {
        function()
            local bufnr = vim.api.nvim_get_current_buf()
            local cached = vim.b[bufnr].lualine_git_repo
            if cached ~= nil then return cached end

            local dir = vim.fn.expand("%:p:h")
            local result = vim.fn.system("git -C " .. vim.fn.shellescape(dir) .. " rev-parse --show-toplevel 2>/dev/null")
            local repo = result ~= "" and vim.fn.fnamemodify(vim.trim(result), ":t") or ""
            vim.b[bufnr].lualine_git_repo = repo
            return repo
        end,
    },
    diff = {
        "diff",
        colored = false,
    },
    lsp_client = {
        function(msg)
            msg = msg or ""

            local buf_clients = vim.lsp.get_clients({ bufnr = 0 })
            if next(buf_clients) == nil then
                if type(msg) == "boolean" or #msg == 0 then
                    return ""
                end
                return msg
            end

            local buf_ft = vim.bo.filetype
            local buf_client_names = {}

            for _, client in pairs(buf_clients) do
                table.insert(buf_client_names, client.name)
            end

            local ok_conform, conform = pcall(require, "conform")
            if ok_conform then
                for _, f in ipairs(conform.list_formatters_for_buffer()) do
                    table.insert(buf_client_names, type(f) == "string" and f or f.name)
                end
            end

            local ok_lint, lint = pcall(require, "lint")
            if ok_lint then
                local linters = lint.linters_by_ft[buf_ft] or {}
                vim.list_extend(buf_client_names, linters)
            end

            local hash = {}
            local client_names = {}
            for _, v in ipairs(buf_client_names) do
                if not hash[v] then
                    client_names[#client_names + 1] = v
                    hash[v] = true
                end
            end
            table.sort(client_names)
            return icons.ui.ActiveLSP .. " " .. table.concat(client_names, ", ") .. " " .. icons.ui.ActiveLSP
        end,
        colored = true,
        on_click = function()
            vim.cmd([[LspInfo]])
        end,
    },
    noice_mode = {
        function()
            return require("noice").api.status.mode.get()
        end,
        cond = function()
            return package.loaded["noice"] and require("noice").api.status.mode.has()
        end,
        color = fg("Constant"),
    },
    noice_command = {
        function()
            return require("noice").api.status.command.get()
        end,
        cond = function()
            return package.loaded["noice"] and require("noice").api.status.command.has()
        end,
        color = fg("Statement"),
    },
}
