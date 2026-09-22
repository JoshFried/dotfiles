--- Keeps AeroSpace workspace placement and SketchyBar indicators synchronized.

local log = hs.logger.new("aerospace", "debug")
local M = {}
local refreshTimer
local refreshPending = false
local refreshPassesRemaining = 0
local assignmentTask
local sketchyBarTask
local scheduleDesktopRefresh

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
    refreshPassesRemaining = 3
    scheduleDesktopRefresh(2)
end

M.screenWatcher = hs.screen.watcher.new(handleScreenChange)
M.screenWatcher:start()
handleScreenChange()

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
