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

            -- TODO: hardcoded to macOS Apple Silicon homebrew path
            local cfr = "/opt/homebrew/bin/cfr-decompiler"
            local cmd
            if class_path then
                local class_name = class_path:gsub("/", "."):gsub("%.class$", "")
                cmd = { cfr, jar, class_name }
            else
                cmd = { cfr, jar }
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
-- When show_document navigates to a jar:// URI, the BufReadCmd kicks off an
-- async CFR decompile. Meanwhile show_document tries to place the cursor at
-- location.range.start which is past EOL of the still-empty buffer, causing
-- "Invalid cursor line: out of range".
--
-- Verified still reproducing on nvim 0.12.2 (2026-05-06).
-- PR #38566 in 0.12.2 fixed a different scenario (insert-mode cursor past
-- EOL), not this async buffer-population race.
--
-- Suppresses the cursor error and retries after content is ready.
local orig_show_document = vim.lsp.util.show_document
vim.lsp.util.show_document = function(location, offset_encoding, opts)
    local ok, err = pcall(orig_show_document, location, offset_encoding, opts)
    if not ok and err:match("Invalid cursor") then
        vim.defer_fn(function()
            pcall(orig_show_document, location, offset_encoding, opts)
        end, 1000)
    end
end

-- Removed 2026-05-08: apply_text_document_edit wrapper that guarded against
-- nil / zero buf_versions from kotlin-lsp and rust-analyzer workspace edits.
-- nvim 0.12.2's upstream implementation now:
--   1. defaults buf_versions[bufnr] to 0 via metatable __index
--   2. guards against text_document.version == vim.NIL
--   3. guards against text_document.version == 0
-- The wrapper was also dropping the 4th arg (change_annotations), silently
-- breaking rename for annotated edits. If nil-version errors resurface on a
-- future nvim release, restore from git history and forward with varargs.

-- kotlin-ls sends stale textDocument.version in workspace edits (e.g. rename).
-- When format-on-save bumps the buffer version between the request and response,
-- nvim rejects the edit with "Buffer ... newer than edits". Zero out the version
-- so nvim skips the check. Forwards all args including change_annotations.
local orig_apply_text_document_edit = vim.lsp.util.apply_text_document_edit
vim.lsp.util.apply_text_document_edit = function(text_document_edit, index, ...)
    local dominated_by_kotlin = false
    for _, client in ipairs(vim.lsp.get_clients()) do
        if client.name == "kotlin_lsp" then
            dominated_by_kotlin = true
            break
        end
    end
    if dominated_by_kotlin then
        text_document_edit.textDocument.version = 0
    end
    return orig_apply_text_document_edit(text_document_edit, index, ...)
end