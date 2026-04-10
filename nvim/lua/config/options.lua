-- Set JAVA_HOME for coursier (Java is already in PATH)
vim.env.JAVA_HOME = vim.env.JAVA_HOME or "/Library/Java/JavaVirtualMachines/amazon-corretto-21.jdk/Contents/Home"

vim.opt.guicursor = ""
vim.opt.nu = true
vim.opt.relativenumber = true

vim.opt.splitbelow = true
vim.opt.splitright = true


vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.virtualedit = 'block'

vim.opt.expandtab = true

vim.opt.smartindent = true

vim.opt.wrap = false

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.termguicolors = true

vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

vim.opt.updatetime = 50

vim.opt.colorcolumn = "120"

-- Enable mouse mode
vim.o.mouse = "a"

--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.o.clipboard = "unnamedplus"

-- Enable break indent
vim.o.breakindent = true

-- Save undo history
vim.o.undofile = true

-- Case insensitive searching UNLESS /C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true

-- Keep signcolumn on by default
vim.wo.signcolumn = "yes"

-- Decrease update time
vim.o.timeout = true
vim.o.timeoutlen = 300

-- Set completeopt to have a better completion experience
vim.o.completeopt = "menuone,noselect"

vim.g.mapleader = " "
vim.g.maplocalleader = ","
vim.diagnostics_mode = 3
-- vim.diagnostics_mode = 3 -- set the visibility of diagnostics in the UI (0=off, 1=only show in status line, 2=virtual text off, 3=all on)
vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })


vim.g.loaded_netrwPlugin = 1
vim.g.loaded_netrw = 1

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
                -- Plain .class file — decompile directly
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
-- We set this flag early so jdtls's plugin/jdtls.lua skips its autocmd registration.
-- jdtls's LspAttach and commands are re-registered in the jdtls.lua plugin config.
vim.g.nvim_jdtls = 1

-- Workaround for telescope + jdtls async decompile race condition in nvim 0.12.
-- When go-to-definition lands on a .class file, jdtls decompiles it async but
-- telescope tries to set cursor before content is ready. This suppresses the error.
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
-- Sets the edit version to match the current buffer version.
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
