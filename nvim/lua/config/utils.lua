local M = {}

function M.EqualizeSplits()
    vim.cmd("wincmd =") -- Equalize the size of all windows
end

function M.SmartDelete()
    if vim.fn.getline(".") == "" then return '"_dd' end
    return "dd"
end

-- ty @ https://github.com/adibhanna/nvim/blob/main/lua/config/utils.lua
function M.CopyFilePathAndLineNumber()
    local current_file = vim.fn.expand("%:p")
    local current_line = vim.fn.line(".")
    local is_git_repo = vim.fn.system("git rev-parse --is-inside-work-tree"):match("true")

    if is_git_repo then
        local current_repo = vim.fn.systemlist("git remote get-url origin")[1]
        local current_branch = vim.fn.systemlist("git rev-parse --abbrev-ref HEAD")[1]

        -- Convert Git URL to GitHub web URL format
        current_repo = current_repo:gsub("git@github.com:", "https://github.com/")
        current_repo = current_repo:gsub("%.git$", "")

        -- Remove leading system path to repository root
        local repo_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
        if repo_root then
            current_file = current_file:sub(#repo_root + 2)
        end

        local url = string.format("%s/blob/%s/%s#L%s", current_repo, current_branch, current_file, current_line)
        vim.fn.setreg("+", url)
        print("Copied to clipboard: " .. url)
    else
        -- If not in a Git directory, copy the full file path
        vim.fn.setreg("+", current_file .. "#L" .. current_line)
        print("Copied full path to clipboard: " .. current_file .. "#L" .. current_line)
    end
end

return M
