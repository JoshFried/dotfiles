--- Toggles selected applications as centered floating windows on the main display.

local bindings = require("bindings")
local windows = require("hs.window")
local screen = require("hs.screen")
--- `hs.spaces` uses private macOS APIs, so centering remains available when it fails.
local ok, spaces = pcall(require, "hs.spaces")
if not ok then spaces = nil end
local applications = require("hs.application")

--- Resizes, centers, and focuses a window within a screen frame.
---@param win hs.window
---@param screenFrame hs.geometry
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

--- Returns the usable frame of the current main screen.
---@return hs.geometry
local function getMainFrame()
    local mainScreen = screen.mainScreen()
    return mainScreen:frame()
end

--- Hides a frontmost app or centers its first available window.
---@param app string Application name.
local function centered(app)
    local application = applications.find(app)
    local mainScreen = screen.mainScreen()
    local mainFrame = mainScreen:frame()

    if application then
        if application:isFrontmost() then
            application:hide()
            return
        end

        local existingWindows = application:allWindows()

        for _, win in ipairs(existingWindows) do
            if win:screen() ~= mainScreen then
                win:moveToScreen(mainScreen)
            end

            handleCenter(win, mainFrame)
            return
        end
    end

    local launch = launchOrActivateApp(app)

    if launch then
        local launchedApplication = applications.get(app)
        if launchedApplication ~= nil then
            local w = launchedApplication:mainWindow()
            if spaces and w then
                local space = spaces.focusedSpace()
                spaces.moveWindowToSpace(w, space)
                handleCenter(w, getMainFrame())
                spaces.gotoSpace(space)
            elseif w then
                handleCenter(w, getMainFrame())
            end
        end
    end
end

local apps = {
    { key = "E", app = "Messages" },
    { key = "A", app = "Music" },
    { key = "P", app = "Podcasts" },
    { key = "W", app = "Notes" },
    { key = "T", app = "Telegram" },
    { key = "F", app = "Finder" },
}

for _, mappings in ipairs(apps) do
    bindings.bind({
        group = "Floating applications",
        title = mappings.app,
        modifiers = { "cmd", "ctrl" },
        key = mappings.key,
        action = function()
            centered(mappings.app)
        end,
    })
end
