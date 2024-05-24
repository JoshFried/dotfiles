local icons = require("config.icons")

local M = {
    {
        "mfussenegger/nvim-dap",
        dependencies = {
            { "rcarriga/nvim-dap-ui" },
            { "theHamsta/nvim-dap-virtual-text" },
            { "nvim-telescope/telescope-dap.nvim" },
            { "jay-babu/mason-nvim-dap.nvim" },
            { "jbyuki/one-small-step-for-vimkind" },
            { "LiadOz/nvim-dap-repl-highlights",  opts = {} },
        },
        -- stylua: ignore
        keys = {
            { "<leader>dR",  function() require("dap").run_to_cursor() end,                               desc = "Run to Cursor", },
            { "<leader>dE",  function() require("dapui").eval(vim.fn.input "[Expression] > ") end,        desc = "Evaluate Input", },
            { "<leader>dC",  function() require("dap").set_breakpoint(vim.fn.input "[Condition] > ") end, desc = "Conditional Breakpoint", },
            { "<leader>dU",  function() require("dapui").toggle() end,                                    desc = "Toggle UI", },
            { "<leader>db",  function() require("dap").step_back() end,                                   desc = "Step Back", },
            { "<leader>dc",  function() require("dap").continue() end,                                    desc = "Continue", },
            { "<leader>dd",  function() require("dap").disconnect() end,                                  desc = "Disconnect", },
            { "<leader>de",  function() require("dapui").eval() end,                                      mode = { "n", "v" },             desc = "Evaluate", },
            { "<leader>dg",  function() require("dap").session() end,                                     desc = "Get Session", },
            { "<leader>dh",  function() require("dap.ui.widgets").hover() end,                            desc = "Hover Variables", },
            { "<leader>dS",  function() require("dap.ui.widgets").scopes() end,                           desc = "Scopes", },
            { "<leader>di",  function() require("dap").step_into() end,                                   desc = "Step Into", },
            { "<leader>do",  function() require("dap").step_over() end,                                   desc = "Step Over", },
            { "<leader>dp",  function() require("dap").pause.toggle() end,                                desc = "Pause", },
            { "<leader>dq",  function() require("dap").close() end,                                       desc = "Quit", },
            { "<leader>dr",  function() require("dap").repl.toggle() end,                                 desc = "Toggle REPL", },
            { "<leader>ds",  function() require("dap").continue() end,                                    desc = "Start", },
            { "<leader>dt",  function() require("dap").toggle_breakpoint() end,                           desc = "Toggle Breakpoint", },
            { "<leader>dx",  function() require("dap").terminate() end,                                   desc = "Terminate", },
            { "<leader>du",  function() require("dap").step_out() end,                                    desc = "Step Out", },
            { "<leader>dcb", function() require("dap").clear_breakpoints() end,                           desc = "Step Out", },
        },
        config = function(plugin, opts)
            require("nvim-dap-virtual-text").setup({
                commented = true,
            })

            local dap, dapui = require("dap"), require("dapui")
            -- dapui.setup({})

            dap.listeners.after.event_initialized["dapui_config"] = function()
                dapui.open()
            end
            dap.listeners.before.event_terminated["dapui_config"] = function()
                dapui.close()
            end
            dap.listeners.before.event_exited["dapui_config"] = function()
                dapui.close()
            end

            -- set up debugger
            if opts ~= nil then
                for k, _ in pairs(opts.setup) do
                    opts.setup[k](plugin, opts)
                end
            end
        end,
    },
    {
        "rcarriga/nvim-dap-ui",
        keys = {
            {
                "<leader>du",
                function()
                    require("dapui").toggle()
                end,
                silent = true,
            },
        },
        opts = {
            -- icons = { expanded = "∩â¥", collapsed = "∩âÜ", circular = "∩äÉ" },
            mappings = {
                expand = { "<CR>", "<2-LeftMouse>" },
                open = "o",
                remove = "d",
                edit = "e",
                repl = "r",
                toggle = "t",
            },
            layouts = {
                {
                    elements = {
                        { id = "repl",    size = 0.30 },
                        { id = "console", size = 0.70 },
                    },
                    size = 0.25,
                    position = "bottom",
                },
                {
                    elements = {
                        { id = "scopes",      size = 0.30 },
                        { id = "breakpoints", size = 0.20 },
                        { id = "stacks",      size = 0.10 },
                        { id = "watches",     size = 0.30 },
                    },
                    size = 0.35,
                    position = "left",
                },
            },
            controls = {
                enabled = true,
                element = "repl",
            },
            floating = {
                max_height = 0.9,
                max_width = 0.5,
                border = vim.g.border_chars,
                mappings = {
                    close = { "q", "<Esc>" },
                },
            },
        },
        config = function(_, opts)
            -- local icons = require("core.icons").dap
            -- for name, sign in pairs(icons) do
            --     ---@diagnostic disable-next-line: cast-local-type
            --     sign = type(sign) == "table" and sign or { sign }
            --     vim.fn.sign_define("Dap" .. name, { text = sign[1] })
            -- end
            require("dapui").setup(opts)
        end,
    },
    --TODO: to configure
    {
        "jay-babu/mason-nvim-dap.nvim",
        dependencies = "mason.nvim",
        cmd = { "DapInstall", "DapUninstall" },
        opts = {
            automatic_setup = true,
            handlers = {},
            ensure_installed = {},
        },
    },
}

vim.fn.sign_define("DapBreakpoint", { text = icons.ui.DapBreakpoint, texthl = "Error", linehl = "", numhl = "" })
vim.fn.sign_define(
    "DapBreakpointRejected",
    { text = icons.ui.DapBreakpointRejected, texthl = "Error", linehl = "", numhl = "" }
)
vim.fn.sign_define(
    "DapStopped",
    { text = icons.ui.DapBreakpointStopped, texthl = "DiagnosticSignInfo", linehl = "", numhl = "" }
)

return M
