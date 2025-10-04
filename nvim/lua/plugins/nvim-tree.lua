return {
    "nvim-tree/nvim-tree.lua",
    commit = "c3c6544ee00333b0f1d6a13735d0dd302dba4f70",
    cmd = { "NvimTreeToggle" },
    keys = {
        { "<leader>pv", "<cmd>NvimTreeToggle<cr>", desc = "Explorer" },
        { "<leader>pf", "<cmd>NvimTreeFocus<cr>",  desc = "Explorer" },
    },
    opts = {
        disable_netrw = false,
        hijack_netrw = true,
        respect_buf_cwd = true,
        view = {
            number = true,
            relativenumber = true,
        },
        filters = {
            custom = { ".git" },
        },
        git = {
            enable = true,
            ignore = false
        },
        sync_root_with_cwd = true,
        update_focused_file = {
            enable = true,
            update_root = true,
        },
        actions = {
            open_file = {
                quit_on_open = true,
            },
        },
        log = {
            enable = true,
            truncate = true,
            types = {
                diagnostics = true,
                git = true,
                profile = true,
                watcher = true,
            },
        },
    },
}
