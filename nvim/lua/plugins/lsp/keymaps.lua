local M = {}

function M.on_attach(client, buffer)
    local self = M.new(client, buffer)

    self:map("gr", "Telescope lsp_references", { desc = "References" })
    self:map("gd", function() require("telescope.builtin").lsp_definitions({ reuse_win = true }) end,
        { desc = "Goto Definition" })

    self:map("gb", "Telescope lsp_type_definitions", { desc = "Goto Type Definition" })
    self:map("K", vim.lsp.buf.hover, { desc = "Hover" })

    -- stylua: ignore
    self:map("gI", function() require("telescope.builtin").lsp_implementations({ reuse_win = true }) end,
        { desc = "Goto Implementation" })
    -- stylua: ignore
    self:map("gy", function() require("telescope.builtin").lsp_type_definitions({ reuse_win = true }) end,
        { desc = "Goto Type Definition" })
    self:map("gK", vim.lsp.buf.signature_help, { desc = "Signature Help", has = "signatureHelp" })
    self:map("[d", M.diagnostic_goto(true), { desc = "Next Diagnostic" })
    self:map("]d", M.diagnostic_goto(false), { desc = "Prev Diagnostic" })
    self:map("]e", M.diagnostic_goto(true, "ERROR"), { desc = "Next Error" })
    self:map("[e", M.diagnostic_goto(false, "ERROR"), { desc = "Prev Error" })
    self:map("]w", M.diagnostic_goto(true, "WARNING"), { desc = "Next Warning" })
    self:map("[w", M.diagnostic_goto(false, "WARNING"), { desc = "Prev Warning" })
    self:map("<leader>ca", vim.lsp.buf.code_action, { desc = "Code Action", mode = { "n", "v" }, has = "codeAction" })
    local toggle_format = require("plugins.lsp.format").toggle
    self:map("<leader>TT", toggle_format, { desc = "Toggle Autoformatting On/Off" })

    local format = require("plugins.lsp.format").format
    self:map("<leader>cf", format, { desc = "Format Document", has = "documentFormatting" })
    self:map("<leader>cf", format, { desc = "Format Range", mode = "v", has = "documentRangeFormatting" })
    self:map("<leader>rn", M.rename, { expr = true, desc = "Rename", has = "rename" })

    self:map("<leader>cs", require("telescope.builtin").lsp_document_symbols, { desc = "Document Symbols" })
    self:map("<leader>cS", require("telescope.builtin").lsp_dynamic_workspace_symbols, { desc = "Workspace Symbols" })
    self:map("<leader>h", function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
    end, { desc = "toggle inlay hints" })
end

function M.new(client, buffer)
    return setmetatable({ client = client, buffer = buffer }, { __index = M })
end

function M:has(cap)
    return self.client.server_capabilities[cap .. "Provider"]
end

function M:map(lhs, rhs, opts)
    opts = opts or {}
    if opts.has and not self:has(opts.has) then
        return
    end
    vim.keymap.set(
        opts.mode or "n",
        lhs,
        type(rhs) == "string" and ("<cmd>%s<cr>"):format(rhs) or rhs,
        ---@diagnostic disable-next-line: no-unknown
        { silent = true, buffer = self.buffer, expr = opts.expr, desc = opts.desc }
    )
end

function M.rename()
    for _, client in ipairs(vim.lsp.get_active_clients()) do
        if client.name == "typescript-tools" then
            vim.lsp.buf.rename()
            return
        end
    end

    if pcall(require, "inc_rename") then
        return ":IncRename " .. vim.fn.expand("<cword>")
    else
        vim.lsp.buf.rename()
    end
end

function M.diagnostic_goto(next, severity)
    local go = next and vim.diagnostic.goto_next or vim.diagnostic.goto_prev
    severity = severity and vim.diagnostic.severity[severity] or nil
    return function()
        go({ severity = severity })
    end
end

return M
