local M = {
    {
        "mfussenegger/nvim-jdtls",
        ft = "java",
        keys = {
            {
                "<leader>rn", vim.lsp.buf.rename, desc = "Rename"
            }
        },
        init = function()
            vim.g.jdtls_manually_configured = true

            local isWork, workStuff = pcall(require, "plugins.lsp.work")

            local group = vim.api.nvim_create_augroup("CustomJdtlsSetup", { clear = true })
            vim.api.nvim_create_autocmd("FileType", {
                group = group,
                pattern = "java",
                callback = function()
                    -- Only set up if not already set up for this buffer
                    if vim.b.jdtls_setup_done then
                        return
                    end

                    -- Always try work config first
                    if isWork then
                        workStuff.setupJavaWorkEnvrionment()
                        vim.b.jdtls_setup_done = true
                    else
                        -- Fall back to default config if work config isn't found
                        local jdtls = require('jdtls')
                        local home = os.getenv('HOME')
                        local root_dir = require('jdtls.setup').find_root({ 'gradlew', '.git', 'mvnw' })
                        local workspace_folder = home ..
                            "/.cache/jdtls/workspace/" .. vim.fn.fnamemodify(root_dir, ":p:h:t")

                        local config = {
                            cmd = {
                                'jdtls',
                                '-data', workspace_folder,
                            },
                            root_dir = root_dir,
                        }

                        jdtls.start_or_attach(config)
                        vim.b.jdtls_setup_done = true
                    end
                end,
                -- Run once per buffer
                once = false,
            })
        end,
    }
}

return M
