local keymap = vim.keymap.set

-- Load all keymap modules
local modules = {
    'core',
    'windows',
    'text',
    'clipboard',
    'files',
    'lsp',
    'search',
    'utility',
    'telescope',
}

-- Apply keymaps from each module
local function apply_keymaps(group)
    for _, map in ipairs(group) do
        if map[1] and map[2] and map[3] then
            keymap(map[1], map[2], map[3], map[4])
        end
    end
end

-- Load and apply all keymap modules
for _, module in ipairs(modules) do
    local ok, keymaps = pcall(require, 'config.keymaps.' .. module)
    if ok and keymaps and #keymaps > 0 then
        if module == 'telescope' then
            -- Special handling for telescope keymaps
            for _, map in ipairs(keymaps) do
                if map[1] and map[2] then
                    keymap("n", map[1], map[2], { desc = map.desc })
                end
            end
        else
            apply_keymaps(keymaps)
        end
    elseif not ok then
        vim.notify("Failed to load keymap module: " .. module, vim.log.levels.WARN)
    end
end
