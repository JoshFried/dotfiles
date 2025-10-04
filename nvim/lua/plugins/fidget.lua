return {
    {
        "j-hui/fidget.nvim",
        event = "LspAttach",
        config = function()
            local ok, fidget = pcall(require, "fidget")
            if not ok then
                vim.notify("Failed to load fidget.nvim", vim.log.levels.ERROR)
                return
            end
            
            fidget.setup({
                progress = {
                    poll_rate = 0,
                    suppress_on_insert = false,
                    ignore_done_already = false,
                    ignore_empty_message = false,
                    display = {
                        render_limit = 16,
                        done_ttl = 3,
                        done_icon = "✔",
                        done_style = "Constant",
                        progress_ttl = math.huge,
                        progress_icon = { pattern = "dots", period = 1 },
                        progress_style = "WarningMsg",
                        group_style = "Title",
                        icon_style = "Question",
                        priority = 30,
                        skip_history = true,
                        format_message = require("fidget.progress.display").default_format_message,
                        format_annote = function(msg) return msg.title end,
                        format_group_name = function(group) return tostring(group) end,
                        overrides = {
                            rust_analyzer = { name = "rust-analyzer" },
                        },
                    },
                },
                notification = {
                    poll_rate = 10,
                    filter = vim.log.levels.INFO,
                    history_size = 128,
                    override_vim_notify = false,
                    configs = { default = require("fidget.notification").default_config },
                    redirect = function(msg, level, opts)
                        if opts and opts.on_open then
                            return require("fidget.integration.nvim-notify").delegate(msg, level, opts)
                        end
                    end,
                    view = {
                        stack_upwards = true,
                        icon_separator = " ",
                        group_separator = "---",
                        group_separator_hl = "Comment",
                        render_message = function(msg, cnt)
                            return cnt == 1 and msg or string.format("(%dx) %s", cnt, msg)
                        end,
                    },
                    window = {
                        normal_hl = "Comment",
                        winblend = 100,
                        border = "none",
                        zindex = 45,
                        max_width = 0,
                        max_height = 0,
                        x_padding = 1,
                        y_padding = 0,
                        align = "bottom",
                        relative = "editor",
                    },
                },
            })
        end,
    },
}
