--- Keeps AeroSpace workspace placement and SketchyBar indicators synchronized.

local log = hs.logger.new("aerospace", "debug")
local M = {}
local refreshTimer
local refreshPending = false
local refreshPassesRemaining = 0
local assignmentTask
local sketchyBarTask
local snapshotTask
local snapshotDebounceTimer
local stableScreenCount
local desktopRefreshCallbacks = {}
local scheduleDesktopRefresh
local scheduleWorkspaceSnapshot
local startSnapshotTracking

local paths = {
    aerospace = "/opt/homebrew/bin/aerospace",
    sketchybar = "/opt/homebrew/bin/sketchybar",
    workspaceAssign = os.getenv("HOME") .. "/.config/aerospace-workspace-assign.sh",
}

--- Logs non-empty task output one line at a time.
---@param level "i"|"e" Logger method name.
---@param label string Task label.
---@param output? string Captured process output.
local function logOutput(level, label, output)
    if not output or output == "" then
        return
    end

    for line in output:gmatch("[^\r\n]+") do
        log[level](label .. ": " .. line)
    end
end

--- Applies the environment shared by desktop automation tasks.
---@param task hs.task
local function configureTask(task)
    local environment = task:environment()
    environment.PATH = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
    task:setEnvironment(environment)
end

--- Captures window-to-workspace membership while the display topology is stable.
local function snapshotWorkspaces()
    if assignmentTask or snapshotTask or not stableScreenCount then
        return
    end

    local screenCount = #hs.screen.allScreens()
    if screenCount ~= stableScreenCount then
        return
    end

    snapshotTask = hs.task.new(paths.workspaceAssign, function(exitCode, stdOut, stdErr)
        snapshotTask = nil
        logOutput("i", "Workspace snapshot", stdOut)

        if exitCode ~= 0 and exitCode ~= 75 then
            logOutput("e", "Workspace snapshot", stdErr)
            log.e(string.format("Workspace snapshot failed with exit code %d", exitCode))
        end
    end, { "snapshot", tostring(screenCount) })

    if not snapshotTask then
        log.e("Unable to create workspace snapshot task")
        return
    end

    configureTask(snapshotTask)
    if not snapshotTask:start() then
        snapshotTask = nil
        log.e("Unable to start workspace snapshot task")
    end
end

--- Coalesces bursts of window activity into a single workspace snapshot.
scheduleWorkspaceSnapshot = function(delay)
    if snapshotDebounceTimer then
        snapshotDebounceTimer:stop()
    end

    snapshotDebounceTimer = hs.timer.doAfter(delay or 0.5, function()
        snapshotDebounceTimer = nil
        snapshotWorkspaces()
    end)
end

--- Resumes event-driven snapshots after monitor-aware workspace placement settles.
startSnapshotTracking = function(delay)
    stableScreenCount = #hs.screen.allScreens()
    scheduleWorkspaceSnapshot(delay)
end

local function notifyDesktopRefreshCallbacks()
    for _, callback in ipairs(desktopRefreshCallbacks) do
        local ok, errorMessage = xpcall(callback, debug.traceback)
        if not ok then
            log.e("Desktop refresh callback failed: " .. errorMessage)
        end
    end
end

--- Reloads SketchyBar after monitor-aware workspace assignment completes.
local function reloadSketchyBar()
    if sketchyBarTask then
        log.w("SketchyBar reload is already running")
        return
    end

    sketchyBarTask = hs.task.new(paths.sketchybar, function(exitCode, stdOut, stdErr)
        sketchyBarTask = nil
        logOutput("i", "SketchyBar reload", stdOut)
        logOutput("e", "SketchyBar reload", stdErr)

        if exitCode == 0 then
            log.i("SketchyBar reloaded after display change")
        else
            log.e(string.format("SketchyBar reload failed with exit code %d", exitCode))
        end
    end, { "--reload" })

    if not sketchyBarTask then
        log.e("Unable to create SketchyBar reload task")
        return
    end

    configureTask(sketchyBarTask)
    if not sketchyBarTask:start() then
        sketchyBarTask = nil
        log.e("Unable to start SketchyBar reload task")
    end
end

--- Reassigns workspaces and reloads display-dependent SketchyBar items.
local function refreshDesktopState()
    if assignmentTask then
        refreshPending = true
        log.i("Display changed during workspace assignment; another refresh is queued")
        return
    end

    log.i("Display configuration changed; reassigning workspaces")
    assignmentTask = hs.task.new(paths.workspaceAssign, function(exitCode, stdOut, stdErr)
        assignmentTask = nil
        logOutput("i", "Workspace assignment", stdOut)
        logOutput("e", "Workspace assignment", stdErr)

        if refreshPending then
            refreshPending = false
            scheduleDesktopRefresh()
            return
        end

        if refreshPassesRemaining > 1 then
            refreshPassesRemaining = refreshPassesRemaining - 1
            log.i(string.format(
                "Scheduling display stabilization pass; %d remaining",
                refreshPassesRemaining
            ))
            scheduleDesktopRefresh(3)
            return
        end

        refreshPassesRemaining = 0
        if exitCode ~= 0 then
            log.e(string.format("Workspace assignment failed with exit code %d", exitCode))
            hs.alert.show("Workspace assignment failed; check the Hammerspoon console")
            return
        end

        notifyDesktopRefreshCallbacks()
        startSnapshotTracking(1.5)
        reloadSketchyBar()
    end, {})

    if not assignmentTask then
        log.e("Unable to create workspace assignment task")
        return
    end

    configureTask(assignmentTask)
    if not assignmentTask:start() then
        assignmentTask = nil
        log.e("Unable to start workspace assignment task")
    end
end

--- Debounces the burst of screen events emitted during display changes.
scheduleDesktopRefresh = function(delay)
    if refreshTimer then
        refreshTimer:stop()
    end

    refreshTimer = hs.timer.doAfter(delay or 2, function()
        refreshTimer = nil
        refreshDesktopState()
    end)
end

--- Starts a fresh stabilization sequence after the screen topology changes.
local function handleScreenChange()
    stableScreenCount = nil
    if snapshotDebounceTimer then
        snapshotDebounceTimer:stop()
        snapshotDebounceTimer = nil
    end
    refreshPassesRemaining = 3
    scheduleDesktopRefresh(2)
end

M.screenWatcher = hs.screen.watcher.new(handleScreenChange)
M.screenWatcher:start()

M.windowWatcher = hs.window.filter.new()
M.windowWatcher:subscribe({
    hs.window.filter.windowCreated,
    hs.window.filter.windowDestroyed,
    hs.window.filter.windowFocused,
    hs.window.filter.windowMoved,
}, scheduleWorkspaceSnapshot)

function M.onDesktopRefresh(callback)
    desktopRefreshCallbacks[#desktopRefreshCallbacks + 1] = callback
end

startSnapshotTracking()

require("bindings").bind({
    group = "Workspaces",
    title = "Previous workspace",
    modifiers = hyper,
    key = "Tab",
    action = function()
        os.execute(paths.aerospace .. " workspace-back-and-forth &")
    end,
})

return M
