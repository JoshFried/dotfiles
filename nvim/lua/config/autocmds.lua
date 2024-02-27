local function augroup(name)
    return vim.api.nvim_create_augroup("mnv_" .. name, { clear = true })
end

-- See `:help vim.highlight.on_yank()`
-- local highlight_group = vim.api.nvim_create_augroup("YankHighlight", { clear = true })
local highlight_group = augroup("YankHighlight")
vim.api.nvim_create_autocmd("TextYankPost", {
    callback = function()
        vim.highlight.on_yank()
    end,
    group = highlight_group,
    pattern = "*",
})

-- Check if we need to reload the file when it changed
vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
    group = augroup("checktime"),
    command = "checktime",
})

-- go to last loc when opening a buffer
vim.api.nvim_create_autocmd("BufReadPost", {
    callback = function()
        local mark = vim.api.nvim_buf_get_mark(0, '"')
        local lcount = vim.api.nvim_buf_line_count(0)
        if mark[1] > 0 and mark[1] <= lcount then
            pcall(vim.api.nvim_win_set_cursor, 0, mark)
        end
    end,
})


-- Auto toggle hlsearch
local ns = vim.api.nvim_create_namespace("toggle_hlsearch")
local function toggle_hlsearch(char)
    if vim.fn.mode() == "n" then
        local keys = { "<CR>", "n", "N", "*", "#", "?", "/" }
        local new_hlsearch = vim.tbl_contains(keys, vim.fn.keytrans(char))

        if vim.opt.hlsearch:get() ~= new_hlsearch then
            vim.opt.hlsearch = new_hlsearch
        end
    end
end
vim.on_key(toggle_hlsearch, ns)

-- windows to close
vim.api.nvim_create_autocmd("FileType", {
    pattern = {
        "OverseerForm",
        "OverseerList",
        "floggraph",
        "fugitive",
        "git",
        "help",
        "lspinfo",
        "man",
        "neotest-output",
        "neotest-summary",
        "oil",
        "qf",
        "query",
        "spectre_panel",
        "startuptime",
        "toggleterm",
        "tsplayground",
        "vim",
    },
    callback = function(event)
        vim.bo[event.buf].buflisted = false
        vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
    end,
})

vim.api.nvim_command("autocmd VimResized * wincmd =")

-- ensure we always have a transparent background when we change themes :)
vim.api.nvim_create_autocmd("ColorScheme", {
    callback = function()
        local highlights = {
            "Normal",
            "LineNr",
            "Folded",
            "NonText",
            "SpecialKey",
            "VertSplit",
            "SignColumn",
            "EndOfBuffer",
            "TablineFill", -- this is specific to how I like my tabline to look like
        }
        for _, name in pairs(highlights) do
            vim.cmd.highlight(name .. " guibg=none ctermbg=none")
        end
    end,
})

vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
        -- vim.cmd("<cmd>Telescope diagnostics<cr>")
        vim.cmd("lua require('telescope.builtin').find_files()")
    end,
})

-- allow for 2 space indenting for some files
local setIndent = augroup('setIndent')
vim.api.nvim_create_autocmd('Filetype', {
    group = setIndent,
    pattern = { 'xml', 'html', 'xhtml', 'css', 'scss', 'javascript', 'typescript', 'jsx', 'tsx',
        'typescriptreact', 'javascriptreact'
    },
    command = 'setlocal shiftwidth=2 tabstop=2'
})
