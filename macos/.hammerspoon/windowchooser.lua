local bindings = require("bindings")
local kanagawa = require("kanagawa")

local focusedWindow = hs.window.focusedWindow()
local currentWindowId = focusedWindow and focusedWindow:id() or nil
local previousWindowId = nil
local windowById = {}

hs.window.filter.default:subscribe(hs.window.filter.windowFocused, function(window)
    local id = window:id()
    if id ~= currentWindowId then
        previousWindowId = currentWindowId
        currentWindowId = id
    end
end)

local chooser = hs.chooser.new(function(choice)
    if not choice then
        return
    end

    local window = windowById[choice.id]
    if window then
        window:focus()
    end
end)

kanagawa.styleChooser(chooser, { rows = 12, width = 55 })

local function showWindowChooser()
    windowById = {}
    local choices = {}

    for _, window in ipairs(hs.window.allWindows()) do
        local application = window:application()
        local title = window:title()
        if application and window:isStandard() and title ~= "" then
            local id = tostring(window:id())
            windowById[id] = window
            choices[#choices + 1] = {
                id = id,
                text = title,
                subText = application:name(),
            }
        end
    end

    table.sort(choices, function(left, right)
        if left.subText == right.subText then
            return left.text < right.text
        end
        return left.subText < right.subText
    end)

    chooser:choices(choices)
    chooser:show()
end

local function focusPreviousWindow()
    local window = previousWindowId and hs.window.get(previousWindowId)
    if window then
        window:focus()
    else
        hs.alert.show("No previous window")
    end
end

bindings.bind({
    group = "Windows",
    title = "Find window",
    modifiers = hyper,
    key = "W",
    action = showWindowChooser,
})

bindings.bind({
    group = "Windows",
    title = "Previous window",
    modifiers = hyper,
    key = "delete",
    action = focusPreviousWindow,
})

bindings.bind({
    group = "Windows",
    title = "Previous window",
    modifiers = hyper,
    key = "forwarddelete",
    action = focusPreviousWindow,
    hidden = true,
})
