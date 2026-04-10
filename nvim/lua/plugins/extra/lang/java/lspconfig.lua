local jvm_target = "21"

local M = {
    "neovim/nvim-lspconfig",
    dependencies = { "pmizio/typescript-tools.nvim" },
    opts = {
        servers = {
            kotlin_lsp = {
                settings = {
                    kotlin = {
                        compiler = {
                            jvm = { target = jvm_target },
                        },
                        hints = {
                            typeHints = true,
                            parameterHints = true,
                            chainedHints = true,
                        },
                        completion = {
                            snippets = { enabled = true },
                        },
                        diagnostics = { enabled = true },
                        inlayHints = {
                            typeHints = { enabled = true },
                            parameterHints = { enabled = true },
                            chainedHints = { enabled = true },
                        },
                    },
                },
                -- on_init runs when the LSP actually starts in a project, not at nvim startup.
                -- This lets us detect JVM target from the project's Config/build.gradle.kts
                -- and update the LSP settings dynamically.
                on_init = function(client)
                    local ok, work = pcall(require, "config.work")
                    if ok then
                        local detected = work.detect_jvm_target()
                        if detected then
                            client.config.settings.kotlin.compiler.jvm.target = detected
                            client.notify("workspace/didChangeConfiguration", { settings = client.config.settings })
                        else
                            vim.notify("config.work: could not detect JVM target, using default 21", vim.log.levels.WARN)
                        end
                    end
                end,
            },
        },
        setup = {
            kotlin_lsp = function()
                vim.lsp.enable("kotlin_lsp")
            end,
        },
    },
}

return M
