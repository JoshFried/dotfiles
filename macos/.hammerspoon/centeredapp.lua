local hotkey = require("hs.hotkey")
local windows = require("hs.window")
local screen = require("hs.screen")
local spaces = require("hs.spaces")
local applications = require("hs.application")

local function handleCenter(win, screenFrame)
    local winFrame = win:frame()
    winFrame.h = screenFrame.h / 2
    winFrame.w = screenFrame.w * 0.75
    winFrame.x = screenFrame.x + (screenFrame.w - winFrame.w) / 2
    winFrame.y = screenFrame.y + (screenFrame.h - winFrame.h) / 2
    win:setFrame(winFrame)
    win:centerOnScreen()
    win:focus()
end

local function centered(app)
    local application = applications.find(app)
    local mainScreen = screen.mainScreen()
    local focusedWindow = windows.focusedWindow()
    local mainFrame = mainScreen:frame()
    local focusedSpace = spaces.focusedSpace()
    local handled = false

    if application then
        local existingWindows = application:allWindows()

        for _, win in ipairs(existingWindows) do
            if handled then
                return
            end

            if win:screen() ~= mainScreen then
                win:moveToScreen(mainScreen)
            end

            handleCenter(win, mainFrame)
            handled = true
        end

        if handled then
            return
        end
    end

    local launch = launchOrActivateApp(app)

    if launch then
        local application = applications.get(app)
        local window = application:getWindow()
        spaces.moveWindowToSpace(window, focusedSpace)
        handleCenter(focusedWindow, mainFrame)
    end
end

local apps = {
    { key = "E", app = "Messages" },
    { key = "A", app = "Apple Music" },
    { key = "P", app = "Podcasts" },
    { key = "W", app = "Notes" },
}

for _, mappings in ipairs(apps) do
    hotkey.bind({ "cmd", "ctrl" }, mappings.key, function()
        centered(mappings.app)
    end)
end
