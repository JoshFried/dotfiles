-- Set global editor defaults before lazy.nvim loads. Look here for line numbering,
-- indentation, undo, clipboard and display behavior.

vim.opt.fileformat = "unix"
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
vim.opt.mouse = "a"

--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
if vim.env.SSH_TTY and vim.fn.has("linux") == 1 then
    if vim.env.TMUX then
        vim.g.clipboard = "tmux"
    else
        vim.g.clipboard = "osc52"
    end
end
vim.opt.clipboard = "unnamedplus"

-- Enable break indent
vim.opt.breakindent = true

-- Case insensitive searching UNLESS /C or capital in search
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Decrease update time
vim.opt.timeout = true
vim.opt.timeoutlen = 300

-- Set completeopt to have a better completion experience
vim.opt.completeopt = "menuone,noselect"

vim.g.mapleader = " "
vim.g.maplocalleader = ","
vim.diagnostics_mode = 3
vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

vim.g.loaded_netrwPlugin = 1
vim.g.loaded_netrw = 1
