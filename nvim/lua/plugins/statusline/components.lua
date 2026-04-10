local icons = require("config.icons")
local Job = require("plenary.job")

-- dont really use most of these i should probably remove a bunch of this stuff one day....
local function fg(name)
    return function()
        local hl = vim.api.nvim_get_hl_by_name(name, true)
        return hl and hl.foreground and { fg = string.format("#%06x", hl.foreground) }
    end
end

return {
    spaces = {
        function()
            local shiftwidth = vim.api.nvim_buf_get_option(0, "shiftwidth")
            return icons.ui.Tab .. " " .. shiftwidth
        end,
        padding = 1,
    },
    git_repo = {
        function()
            local results = {}
            local job = Job:new({
                command = "git",
                args = { "rev-parse", "--show-toplevel" },
                cwd = vim.fn.expand("%:p:h"),
                on_stdout = function(_, line)
                    table.insert(results, line)
                end,
            })
            job:sync()
            if results[1] ~= nil then
                return vim.fn.fnamemodify(results[1], ":t")
            else
                return ""
            end
        end,
    },
    separator = {
        function()
            return "%="
        end,
    },
    diff = {
        "diff",
        colored = false,
    },
    diagnostics = {
        "diagnostics",
        sources = { "nvim_diagnostic" },
        diagnostics_color = {
            error = "DiagnosticError",
            warn = "DiagnosticWarn",
            info = "DiagnosticInfo",
            hint = "DiagnosticHint",
        },
        colored = true,
    },
    lsp_client = {
        function(msg)
            msg = msg or ""

            -- local buf_clients = vim.lsp.get_active_clients({ bufnr = 0 })
            local buf_clients = vim.lsp.get_clients({ bufnr = 0 })
            if next(buf_clients) == nil then
                if type(msg) == "boolean" or #msg == 0 then
                    return ""
                end
                return msg
            end

            local buf_ft = vim.bo.filetype
            local buf_client_names = {}

            -- add client
            for _, client in pairs(buf_clients) do
                table.insert(buf_client_names, client.name)
            end

            -- add formatter
            local ok_conform, conform = pcall(require, "conform")
            if ok_conform then
                for _, f in ipairs(conform.list_formatters_for_buffer()) do
                    table.insert(buf_client_names, type(f) == "string" and f or f.name)
                end
            end

            -- add linter
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
