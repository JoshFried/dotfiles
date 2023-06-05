local keymap = vim.keymap.set

keymap("n", "zj", "o<Esc>k", { desc = "Create a line above without insert" })
keymap("n", "zk", "O<Esc>j", { desc = "Create a line below without insert" })
keymap("n", "<leader>pv", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle Neo-Tree" })

keymap("n", "<leader>reh", "<cmd>RustEnableInlayHints<CR>")
keymap("n", "<leader>rdh", "<cmd>RustDisableInlayHints<CR>")

function EqualizeSplits()
	vim.cmd("wincmd =") -- Equalize the size of all windows
end

keymap("n", "<leader>0", ":lua EqualizeSplits()<CR>", { noremap = true, silent = true })

-- Resize window using <shift> arrow keys since we have remapped cmd + h/j/k/l as arrow keys this is really convenient
keymap("n", "<S-Up>", "<cmd>resize +2<CR>")
keymap("n", "<S-Down>", "<cmd>resize -2<CR>")
keymap("n", "<S-Left>", "<cmd>vertical resize -2<CR>")
keymap("n", "<S-Right>", "<cmd>vertical resize +2<CR>")

-- move lines
keymap("n", "<A-j>", ":m .+1<CR>==")
keymap("v", "<A-j>", ":m '>+1<CR>gv=gv")
keymap("i", "<A-j>", "<Esc>:m .+1<CR>==gi")
keymap("n", "<A-k>", ":m .-2<CR>==")
keymap("v", "<A-k>", ":m '<-2<CR>gv=gv")
keymap("i", "<A-k>", "<Esc>:m .-2<CR>==gi")

-- Add undo break-points
keymap("i", ",", ",<c-g>u")
keymap("i", ".", ".<c-g>u")
keymap("i", ";", ";<c-g>u")

keymap("n", "J", "mzJ`z")

-- Center screen after C-d / C-u
keymap("n", "<C-d>", "<C-d>zz")
keymap("n", "<C-u>", "<C-u>zz")

keymap("n", "N", "Nzzzv")

keymap("n", "n", "nzzzv")

-- paste from register without overriding register
keymap("x", "<leader>p", [["_dP]])

-- yank to global(?) clipboard ...i.e. can now paste outside of vim buffers
keymap({ "n", "v" }, "<leader>y", [["+y]])
keymap("n", "<leader>Y", [["+Y]])

-- delete without overwriting vim register
keymap({ "n", "v" }, "<leader>d", [["_d]])

keymap("n", "Q", "<nop>")

-- NOTE: not using tmux anymore...just zellij
-- keymap("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>")
keymap("n", "<leader>f", vim.lsp.buf.format)

-- search and replace word under cursor
keymap("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

-- nice way to exit normal mode
keymap("i", "jj", "<esc>")
keymap("i", "kk", "<esc>")

keymap("n", "<C-H>", "<C-w>h", { desc = "Shift focus to left pane" })
keymap("n", "<C-J>", "<C-w>j", { desc = "Shift focus to bottom pane" })
keymap("n", "<C-K>", "<C-w>k", { desc = "Shift focus to top pane" })
keymap("n", "<C-L>", "<C-w>l", { desc = "Shift focus to right pane" })

keymap("n", "<leader>sv", "<cmd> vsplit<CR><C-w>w", { desc = "Split pane vertically" })
keymap("n", "<leader>sh", "<cmd> split<CR><C-w>w", { desc = "Split pane horizontally" })

-- Diagnostic keymaps
keymap("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to previous diagnostic message" })
keymap("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next diagnostic message" })
keymap("n", "<leader>de", vim.diagnostic.open_float, { desc = "Open floating diagnostic message" })
keymap("n", "<leader>dl", vim.diagnostic.setloclist, { desc = "Open diagnostics list" })

-- Stay in visual mode when changing the indent for selection
keymap("v", "<", "<gv")
keymap("v", ">", ">gv")

-- Map enter to ciw in normal mode
keymap("n", "<CR>", "ciw")
