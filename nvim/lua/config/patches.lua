-- Runtime patches and workarounds for nvim/LSP issues.
-- Keep these separate from options.lua so they're easy to find and remove
-- when upstream fixes land.

-- Restore removed LSP commands from nvim 0.12
vim.api.nvim_create_user_command("LspLog", function() vim.cmd.edit(vim.lsp.get_log_path()) end, {})
vim.api.nvim_create_user_command("LspInfo", function() vim.cmd("checkhealth lsp") end, {})

-- Decompile .class files inside jars when kotlin-lsp navigates to jar:// URIs.
-- Uses CFR standalone decompiler since jdtls can't handle jar:// URIs from kotlin-lsp.
-- Also handles plain *.class files that jdtls would normally handle.
local decompile_group = vim.api.nvim_create_augroup("CfrDecompile", { clear = true })
for _, pattern in ipairs({ "jar://*", "*.class" }) do
    vim.api.nvim_create_autocmd("BufReadCmd", {
        group = decompile_group,
        pattern = pattern,
        callback = function(args)
            local uri = args.match
            local jar, class_path

            if uri:match("^jar://") then
                jar, class_path = uri:match("^jar://(.-)!/(.+)$")
            else
                jar = uri
                class_path = nil
            end

            if not jar then return end

            local buf = vim.api.nvim_get_current_buf()
            vim.bo[buf].buftype = "nofile"
            vim.bo[buf].swapfile = false
            vim.bo[buf].modifiable = true

            local cmd
            if class_path then
                local class_name = class_path:gsub("/", "."):gsub("%.class$", "")
                cmd = { "/opt/homebrew/bin/cfr-decompiler", jar, class_name }
            else
                cmd = { "/opt/homebrew/bin/cfr-decompiler", jar }
            end

            local result = vim.fn.systemlist(cmd)
            if vim.v.shell_error == 0 and #result > 0 then
                vim.api.nvim_buf_set_lines(buf, 0, -1, false, result)
                vim.bo[buf].filetype = "java"
            else
                vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "// Decompilation failed" })
            end
            vim.bo[buf].modifiable = false
        end,
    })
end

-- Prevent jdtls from registering its own *.class BufReadCmd which conflicts with CFR.
vim.g.nvim_jdtls = 1

-- Workaround for telescope + async decompile race condition in nvim 0.12.
-- Suppresses cursor error and retries after content is ready.
local orig_show_document = vim.lsp.util.show_document
vim.lsp.util.show_document = function(location, offset_encoding, opts)
    local ok, err = pcall(orig_show_document, location, offset_encoding, opts)
    if not ok and err:match("Invalid cursor") then
        vim.defer_fn(function()
            pcall(orig_show_document, location, offset_encoding, opts)
        end, 1000)
    end
end

-- Workaround for kotlin-lsp sending version=0 in workspace edits,
-- causing nvim to reject renames with "Buffer newer than edits".
local orig_apply_workspace_edit = vim.lsp.util.apply_workspace_edit
vim.lsp.util.apply_workspace_edit = function(workspace_edit, offset_encoding)
    if workspace_edit.documentChanges then
        for _, change in ipairs(workspace_edit.documentChanges) do
            if change.textDocument and change.textDocument.uri then
                local bufnr = vim.uri_to_bufnr(change.textDocument.uri)
                change.textDocument.version = vim.lsp.util.buf_versions[bufnr] or 0
            end
        end
    end
    return orig_apply_workspace_edit(workspace_edit, offset_encoding)
end
