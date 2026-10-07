--- Applies persistent application-to-workspace profiles through AeroSpace.

local bindings = require("bindings")
local kanagawa = require("kanagawa")

local M = {}
local aerospace = "/opt/homebrew/bin/aerospace"
local settingsKey = "desktopProfiles.active"
local queryTask = nil
local moveTasks = {}
local reconcileTimer = nil
local requestId = 0

local profiles = {
    {
        id = "office",
        title = "Office",
        routes = {
            { app = "Slack", bundleID = "com.tinyspeck.slackmacgap", workspace = "1" },
            { app = "Outlook", bundleID = "com.microsoft.Outlook", workspace = "2" },
            { app = "Ghostty", bundleID = "com.mitchellh.ghostty", workspace = "5" },
            { app = "Firefox", bundleID = "org.mozilla.firefox", workspace = "6" },
            { app = "Zoom", bundleID = "us.zoom.xos", workspace = "7" },
        },
    },
    {
        id = "personal",
        title = "Personal",
        routes = {
            { app = "Discord", bundleID = "com.hnc.Discord", workspace = "1" },
            { app = "Firefox", bundleID = "org.mozilla.firefox", workspace = "2" },
            { app = "Ghostty", bundleID = "com.mitchellh.ghostty", workspace = "3" },
        },
    },
}

local profileById = {}
for _, profile in ipairs(profiles) do
    profile.routesByBundleID = {}
    for _, route in ipairs(profile.routes) do
        profile.routesByBundleID[route.bundleID] = route
    end
    profileById[profile.id] = profile
end

local activeProfileId = hs.settings.get(settingsKey)
if not profileById[activeProfileId] then
    activeProfileId = nil
end

local function stopTasks()
    requestId = requestId + 1

    if queryTask and queryTask:isRunning() then
        queryTask:terminate()
    end
    queryTask = nil

    for task in pairs(moveTasks) do
        if task:isRunning() then
            task:terminate()
        end
    end
    moveTasks = {}
end

local function profileDescription(profile)
    local parts = {}
    for _, route in ipairs(profile.routes) do
        parts[#parts + 1] = route.app .. " " .. route.workspace
    end
    return table.concat(parts, " · ")
end

local function finishReconcile(profile, moved, failed, showFeedback)
    if not showFeedback then
        return
    end

    if failed > 0 then
        hs.alert.show(string.format(
            "%s active · moved %d · failed %d",
            profile.title,
            moved,
            failed
        ))
    elseif moved > 0 then
        hs.alert.show(string.format("%s active · moved %d windows", profile.title, moved))
    else
        hs.alert.show(profile.title .. " active · windows already arranged")
    end
end

local function moveWindows(profile, windows, currentRequest, showFeedback)
    local pending = 0
    local moved = 0
    local failed = 0

    for _, window in ipairs(windows) do
        local route = profile.routesByBundleID[window.bundleID]
        if route and route.workspace ~= window.workspace then
            pending = pending + 1

            local task
            task = hs.task.new(aerospace, function(exitCode)
                moveTasks[task] = nil
                if currentRequest ~= requestId then
                    return
                end

                if exitCode == 0 then
                    moved = moved + 1
                else
                    failed = failed + 1
                end

                pending = pending - 1
                if pending == 0 then
                    finishReconcile(profile, moved, failed, showFeedback)
                end
            end, {
                "move-node-to-workspace",
                "--window-id",
                window.id,
                route.workspace,
            })

            if task then
                moveTasks[task] = true
                if not task:start() then
                    moveTasks[task] = nil
                    failed = failed + 1
                    pending = pending - 1
                end
            else
                failed = failed + 1
                pending = pending - 1
            end
        end
    end

    if pending == 0 then
        finishReconcile(profile, moved, failed, showFeedback)
    end
end

local function parseWindows(output)
    local windows = {}
    for line in (output or ""):gmatch("[^\r\n]+") do
        local windowId, bundleID, workspace = line:match("^([^|]*)|([^|]*)|(.*)$")
        if windowId and windowId ~= "" and bundleID and bundleID ~= "" then
            windows[#windows + 1] = {
                id = windowId,
                bundleID = bundleID,
                workspace = workspace,
            }
        end
    end
    return windows
end

local function reconcile(showFeedback)
    local profile = profileById[activeProfileId]
    if not profile then
        return
    end

    stopTasks()
    local currentRequest = requestId

    local task
    task = hs.task.new(aerospace, function(exitCode, stdOut, stdErr)
        if queryTask == task then
            queryTask = nil
        end
        if currentRequest ~= requestId then
            return
        end

        if exitCode ~= 0 then
            hs.printf("Desktop profiles: %s", stdErr)
            if showFeedback then
                hs.alert.show("Unable to read AeroSpace windows")
            end
            return
        end

        moveWindows(profile, parseWindows(stdOut), currentRequest, showFeedback)
    end, {
        "list-windows",
        "--all",
        "--format",
        "%{window-id}|%{app-bundle-id}|%{workspace}",
    })

    queryTask = task
    if not task or not task:start() then
        queryTask = nil
        if showFeedback then
            hs.alert.show("Unable to start desktop profile")
        end
    end
end

local function selectProfile(profile)
    activeProfileId = profile.id
    hs.settings.set(settingsKey, activeProfileId)
    reconcile(true)
end

local chooser = hs.chooser.new(function(choice)
    if not choice then
        return
    end

    local profile = profileById[choice.id]
    if profile then
        selectProfile(profile)
    end
end)

kanagawa.styleChooser(chooser, { title = "Desktop Profiles", rows = 6, width = 45 })

local function showProfiles()
    local choices = {}
    for _, profile in ipairs(profiles) do
        choices[#choices + 1] = {
            id = profile.id,
            text = profile.title,
            subText = (profile.id == activeProfileId and "✓ Active · " or "")
                .. profileDescription(profile),
        }
    end

    chooser:choices(choices)
    kanagawa.showChooser(chooser)
end

local windowFilter = hs.window.filter.new()
windowFilter:subscribe(hs.window.filter.windowCreated, function(window)
    local profile = profileById[activeProfileId]
    local application = window and window:application()
    local bundleID = application and application:bundleID()
    if not profile or not profile.routesByBundleID[bundleID] then
        return
    end

    if reconcileTimer then
        reconcileTimer:stop()
    end
    reconcileTimer = hs.timer.doAfter(0.4, function()
        reconcileTimer = nil
        reconcile(false)
    end)
end)

bindings.bind({
    group = "Workspaces",
    title = "Desktop profiles",
    modifiers = { "cmd", "alt" },
    key = "P",
    keywords = { "office", "personal", "workspace", "layout", "aerospace" },
    priority = 10,
    action = showProfiles,
})

M.profiles = profiles
M.windowFilter = windowFilter
M.show = showProfiles
M.apply = function(profileId)
    local profile = profileById[profileId]
    if profile then
        selectProfile(profile)
    end
end

return M
