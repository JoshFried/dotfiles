--- Builds a searchable chooser from every visible registered binding.

local bindings = require("bindings")
local kanagawa = require("kanagawa")

local actionById = {}
local chooser = hs.chooser.new(function(choice)
    if not choice then
        return
    end

    local action = actionById[choice.id]
    if action then
        hs.timer.doAfter(0, action.action)
    end
end)

kanagawa.styleChooser(chooser, { rows = 12, width = 45 })

--- Rebuilds and opens the command palette from the current registry.
local function showCommandPalette()
    actionById = {}
    local choices = {}

    for index, action in ipairs(bindings.actions()) do
        local id = tostring(index)
        actionById[id] = action
        choices[#choices + 1] = {
            id = id,
            text = action.title,
            subText = string.format("%s  ·  %s", action.group, action.shortcut),
        }
    end

    chooser:choices(choices)
    chooser:show()
end

bindings.bind({
    group = "System",
    title = "Command palette",
    modifiers = hyper,
    key = ";",
    action = showCommandPalette,
})

bindings.bind({
    group = "System",
    title = "Command palette",
    modifiers = {},
    key = "F18",
    action = showCommandPalette,
    hidden = true,
})
