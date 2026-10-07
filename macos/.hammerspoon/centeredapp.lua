--- Toggles selected applications as centered floating windows on the main display.

local bindings = require("bindings")
local windows = require("hs.window")
local screen = require("hs.screen")
local applications = require("hs.application")
local aerospace = "/opt/homebrew/bin/aerospace"
local activeTasks = {}
local centeringTimers = {}
local windowWaitTimers = {}
local workspaceWaitTimers = {}
local openingApplications = {}

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
    win:focus()

    local windowId = win:id()
    if not windowId then
        return
    end

    if centeringTimers[windowId] then
        centeringTimers[windowId]:stop()
    end

    centeringTimers[windowId] = hs.timer.doAfter(0.6, function()
        centeringTimers[windowId] = nil
        local currentWindow = windows.get(windowId)
        if not currentWindow then
            return
        end

        local acceptedFrame = currentWindow:frame()
        local acceptedScreenFrame = currentWindow:screen():frame()
        acceptedFrame.x = acceptedScreenFrame.x
            + (acceptedScreenFrame.w - acceptedFrame.w) / 2
        acceptedFrame.y = acceptedScreenFrame.y
            + (acceptedScreenFrame.h - acceptedFrame.h) / 2
        currentWindow:setFrame(acceptedFrame)
        currentWindow:focus()
    end)
end

--- Returns the usable frame of the current main screen.
---@return hs.geometry
local function getMainFrame()
    local mainScreen = screen.mainScreen()
    return mainScreen:frame()
end

local function runAeroSpace(arguments, callback)
    local task
    task = hs.task.new(aerospace, function(exitCode, stdOut)
        activeTasks[task] = nil
        callback(exitCode == 0, stdOut or "")
    end, arguments)

    if not task then
        callback(false, "")
        return
    end

    activeTasks[task] = true
    if not task:start() then
        activeTasks[task] = nil
        callback(false, "")
    end
end

local function waitForWorkspaceOne(windowId, attemptsRemaining)
    runAeroSpace({ "list-workspaces", "--focused" }, function(success, output)
        if success and output:match("^%s*1%s*$") then
            workspaceWaitTimers[windowId] = nil
            local currentWindow = windows.get(windowId)
            if currentWindow then
                handleCenter(currentWindow, getMainFrame())
            end
            return
        end

        if attemptsRemaining == 0 then
            workspaceWaitTimers[windowId] = nil
            hs.alert.show("Workspace 1 did not become active")
            return
        end

        workspaceWaitTimers[windowId] = hs.timer.doAfter(0.1, function()
            waitForWorkspaceOne(windowId, attemptsRemaining - 1)
        end)
    end)
end

local function centerOnWorkspaceOne(win)
    local windowId = win:id()
    if not windowId then
        handleCenter(win, getMainFrame())
        return
    end

    runAeroSpace({
        "move-node-to-workspace",
        "--window-id",
        tostring(windowId),
        "1",
    }, function(moved)
        if not moved then
            hs.alert.show("Unable to move " .. win:application():name() .. " to workspace 1")
            handleCenter(win, getMainFrame())
            return
        end

        os.execute(aerospace .. " workspace 1 >/dev/null 2>&1 &")
        if workspaceWaitTimers[windowId] then
            workspaceWaitTimers[windowId]:stop()
        end
        waitForWorkspaceOne(windowId, 20)
    end)
end

local function centeredWindow(application)
    local minimizedWindow
    for _, win in ipairs(application:allWindows()) do
        if win:isStandard() then
            return win
        end
        if win:id() ~= 0 and win:isMinimized() then
            minimizedWindow = minimizedWindow or win
        end
    end
    return minimizedWindow
end

local function waitForWindow(appName)
    if windowWaitTimers[appName] then
        windowWaitTimers[appName]:stop()
    end

    local attemptsRemaining = 30
    local function check()
        local application = applications.find(appName)
        local win = application and centeredWindow(application)
        if win then
            windowWaitTimers[appName] = nil
            openingApplications[appName] = nil
            centerOnWorkspaceOne(win)
            return
        end

        attemptsRemaining = attemptsRemaining - 1
        if attemptsRemaining == 0 then
            windowWaitTimers[appName] = nil
            openingApplications[appName] = nil
            hs.alert.show("Unable to open " .. appName .. " window")
            return
        end

        windowWaitTimers[appName] = hs.timer.doAfter(0.1, check)
    end

    windowWaitTimers[appName] = hs.timer.doAfter(0.1, check)
end

local function openWindowOnWorkspaceOne(appName, attemptsRemaining)
    runAeroSpace({ "list-workspaces", "--focused" }, function(success, output)
        if success and output:match("^%s*1%s*$") then
            local application = applications.find(appName)
            local existingWindow = application and centeredWindow(application)
            if existingWindow then
                openingApplications[appName] = nil
                centerOnWorkspaceOne(existingWindow)
                return
            end

            if application then
                hs.eventtap.keyStroke({ "cmd" }, "n", 0, application)
            else
                applications.launchOrFocus(appName)
            end
            waitForWindow(appName)
            return
        end

        if attemptsRemaining == 0 then
            openingApplications[appName] = nil
            hs.alert.show("Workspace 1 did not become active")
            return
        end

        windowWaitTimers[appName] = hs.timer.doAfter(0.1, function()
            openWindowOnWorkspaceOne(appName, attemptsRemaining - 1)
        end)
    end)
end

local function openWindow(appName)
    if openingApplications[appName] then
        return
    end

    openingApplications[appName] = true
    os.execute(aerospace .. " workspace 1 >/dev/null 2>&1 &")
    openWindowOnWorkspaceOne(appName, 20)
end

--- Hides a frontmost app or centers its first available window.
---@param app string Application name.
local function centered(app)
    local application = applications.find(app)
    local existingWindow = application and centeredWindow(application)

    if existingWindow then
        if existingWindow:isMinimized() then
            existingWindow:unminimize()
            centerOnWorkspaceOne(existingWindow)
            return
        end

        if application:isFrontmost() then
            local focusedWindow = application:focusedWindow() or existingWindow
            focusedWindow:minimize()
            return
        end

        existingWindow:unminimize()
        centerOnWorkspaceOne(existingWindow)
        return
    end

    openWindow(app)
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
        apps = { mappings.app },
        keywords = { "launch", "focus", "floating", "center" },
        action = function()
            centered(mappings.app)
        end,
    })
end
