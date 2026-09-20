local M = {}

local actions = {}

local modifierNames = {
    alt = "⌥",
    cmd = "⌘",
    ctrl = "⌃",
    shift = "⇧",
}

local function shortcutLabel(modifiers, key)
    local labels = {}
    for _, modifier in ipairs(modifiers) do
        labels[#labels + 1] = modifierNames[modifier] or modifier
    end
    labels[#labels + 1] = key
    return table.concat(labels)
end

function M.bind(spec)
    spec.shortcut = shortcutLabel(spec.modifiers, spec.key)
    spec.hotkey = hs.hotkey.bind(spec.modifiers, spec.key, spec.action)
    actions[#actions + 1] = spec
    return spec.hotkey
end

function M.actions()
    local visible = {}
    for _, action in ipairs(actions) do
        if not action.hidden then
            visible[#visible + 1] = action
        end
    end

    table.sort(visible, function(left, right)
        if left.group == right.group then
            return left.title < right.title
        end
        return left.group < right.group
    end)

    return visible
end

return M
