local hotkey = require("hs.hotkey")
local windows = require("hs.window")
local screen = require("hs.screen")
-- hs.spaces uses private macOS APIs that break between OS versions.
-- Fail gracefully if the module can't load; the move-to-space fallback
-- below is only used on first-time app launches, and AeroSpace handles
-- workspace placement anyway.
local ok, spaces = pcall(require, "hs.spaces")
if not ok then spaces = nil end
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

local function getMainFrame()
    local mainScreen = screen.mainScreen()
    return mainScreen:frame()
end

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
    hotkey.bind({ "cmd", "ctrl" }, mappings.key, function()
        centered(mappings.app)
    end)
end
