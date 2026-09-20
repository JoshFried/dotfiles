--- Provides basic macOS Space creation, inspection, and cleanup actions.

local spaces = require("hs.spaces")
local screen = require("hs.screen")

--- Adds a Space to the focused window's screen or the pointer's screen.
local function createSpace()
    local win = hs.window.focusedWindow()
    local scr = win and win:screen() or hs.mouse.getCurrentScreen()
    spaces.addSpaceToScreen(scr)
    hs.alert.show("New Space created")
end

--- Displays the main screen's current Space index.
local function showSpaceNumber()
    local currentSpace = spaces.focusedSpace()
    local allSpaces = spaces.spacesForScreen(screen.mainScreen())
    local idx = hs.fnutils.indexOf(allSpaces, currentSpace)
    hs.alert.show("Space " .. (idx or "?") .. " of " .. #allSpaces, 1)
end

--- Removes empty Spaces from the main screen while preserving the first.
local function closeEmptySpaces()
    local allSpaces = spaces.spacesForScreen(screen.mainScreen())
    local removed = 0
    for i = #allSpaces, 2, -1 do
        if #spaces.windowsForSpace(allSpaces[i]) == 0 then
            spaces.removeSpace(allSpaces[i])
            removed = removed + 1
        end
    end
    hs.alert.show("Removed " .. removed .. " empty spaces")
end

local bindings = require("bindings")

bindings.bind({
    group = "Spaces",
    title = "Create space",
    modifiers = hyper,
    key = "N",
    action = createSpace,
})

bindings.bind({
    group = "Spaces",
    title = "Show space number",
    modifiers = hyper,
    key = "`",
    action = showSpaceNumber,
})

bindings.bind({
    group = "Spaces",
    title = "Close empty spaces",
    modifiers = hyper,
    key = "X",
    action = closeEmptySpaces,
})
