local spaces = require("hs.spaces")
local screen = require("hs.screen")

local function createSpace()
    local win = hs.window.focusedWindow()
    local scr = win and win:screen() or hs.mouse.getCurrentScreen()
    spaces.addSpaceToScreen(scr)
    hs.alert.show("New Space created")
end

local function showSpaceNumber()
    local currentSpace = spaces.focusedSpace()
    local allSpaces = spaces.spacesForScreen(screen.mainScreen())
    local idx = hs.fnutils.indexOf(allSpaces, currentSpace)
    hs.alert.show("Space " .. (idx or "?") .. " of " .. #allSpaces, 1)
end

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

hs.hotkey.bind(hyper, "N", createSpace)
hs.hotkey.bind(hyper, "`", showSpaceNumber)
hs.hotkey.bind(hyper, "X", closeEmptySpaces)
