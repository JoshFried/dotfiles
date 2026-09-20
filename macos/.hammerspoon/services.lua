local bindings = require("bindings")
local kanagawa = require("kanagawa")
local hsreload = require("hsreload")

local M = {}
local log = hs.logger.new("services", "debug")
local activeTasks = {}

local paths = {
    aerospace = "/opt/homebrew/bin/aerospace",
    brew = "/opt/homebrew/bin/brew",
    sketchybar = "/opt/homebrew/bin/sketchybar",
    workspaceAssign = os.getenv("HOME") .. "/.config/aerospace-workspace-assign.sh",
}

local function logLines(level, label, output)
    if not output or output == "" then
        return
    end

    for line in output:gmatch("[^\r\n]+") do
        log[level](label .. ": " .. line)
    end
end

local function runTask(label, executable, arguments)
    log.i(string.format("Starting %s: %s %s", label, executable, table.concat(arguments, " ")))

    local task
    task = hs.task.new(executable, function(exitCode, stdOut, stdErr)
        activeTasks[task] = nil
        logLines("i", label, stdOut)
        logLines("e", label, stdErr)

        if exitCode == 0 then
            log.i(label .. " completed")
            hs.alert.show(label .. " completed")
        else
            log.e(string.format("%s failed with exit code %d", label, exitCode))
            hs.alert.show(label .. " failed; check the Hammerspoon console")
        end
    end, arguments)

    if not task then
        log.e("Unable to create task for " .. label)
        hs.alert.show("Unable to start " .. label)
        return
    end

    local environment = task:environment()
    environment.HOMEBREW_NO_AUTO_UPDATE = "1"
    environment.TMUX = nil
    environment.PATH = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
    task:setEnvironment(environment)

    activeTasks[task] = true
    if not task:start() then
        activeTasks[task] = nil
        log.e("Unable to start " .. label)
        hs.alert.show("Unable to start " .. label)
    end
end

local function restartApplication(name)
    local script = string.format(
        'tell application "%s" to quit\ndelay 1\ntell application "%s" to activate',
        name,
        name
    )
    runTask("Restart " .. name, "/usr/bin/osascript", { "-e", script })
end

local function restartHammerspoon()
    log.i("Restarting Hammerspoon application")
    hs.alert.show("Restarting Hammerspoon")
    local task = hs.task.new("/usr/bin/osascript", nil, {
        "-e",
        'tell application "Hammerspoon" to quit\ndelay 1\ntell application "Hammerspoon" to activate',
    })

    if not task then
        log.e("Unable to create Hammerspoon restart task")
        hs.alert.show("Unable to restart Hammerspoon")
        return
    end

    activeTasks[task] = true
    task:start()
end

local actions = {
    {
        title = "Reload Hammerspoon config",
        detail = "Reload init.lua and all modules",
        action = hsreload.reload,
    },
    {
        title = "Restart Hammerspoon app",
        detail = "Quit and relaunch Hammerspoon",
        action = restartHammerspoon,
    },
    {
        title = "Reload AeroSpace config",
        detail = "Apply .aerospace.toml without restarting",
        action = function()
            runTask("Reload AeroSpace config", paths.aerospace, { "reload-config" })
        end,
    },
    {
        title = "Restart AeroSpace app",
        detail = "Quit and relaunch AeroSpace",
        action = function()
            restartApplication("AeroSpace")
        end,
    },
    {
        title = "Reload SketchyBar config",
        detail = "Recreate the bar from sketchybarrc",
        action = function()
            runTask("Reload SketchyBar config", paths.sketchybar, { "--reload" })
        end,
    },
    {
        title = "Refresh workspace indicators",
        detail = "Re-query AeroSpace windows and workspaces",
        action = function()
            runTask("Refresh workspace indicators", paths.sketchybar, {
                "--trigger",
                "aerospace_workspace_change",
            })
        end,
    },
    {
        title = "Restart SketchyBar service",
        detail = "Restart the Homebrew background service",
        action = function()
            runTask("Restart SketchyBar service", paths.brew, {
                "services",
                "restart",
                "sketchybar",
            })
        end,
    },
    {
        title = "Restart Borders service",
        detail = "Restart the JankyBorders Homebrew service",
        action = function()
            runTask("Restart Borders service", paths.brew, {
                "services",
                "restart",
                "borders",
            })
        end,
    },
    {
        title = "Reassign workspaces to monitors",
        detail = "Run the monitor-aware AeroSpace assignment script",
        action = function()
            runTask("Reassign workspaces", paths.workspaceAssign, {})
        end,
    },
    {
        title = "Log desktop service status",
        detail = "Print service and workspace state to the console",
        action = function()
            runTask("Homebrew services", paths.brew, { "services", "list" })
            runTask("AeroSpace monitors", paths.aerospace, {
                "list-monitors",
                "--format",
                "%{monitor-id}|%{monitor-name}|%{monitor-is-main}",
            })
            runTask("Focused AeroSpace workspace", paths.aerospace, {
                "list-workspaces",
                "--focused",
            })
            runTask("SketchyBar state", paths.sketchybar, { "--query", "bar" })
        end,
    },
    {
        title = "Open Hammerspoon console",
        detail = "Show service logs and Lua errors",
        action = function()
            log.i("Opening Hammerspoon console")
            hs.openConsole(true)
        end,
    },
    {
        title = "Clear Hammerspoon console",
        detail = "Clear existing console output",
        action = function()
            hs.console.clearConsole()
            log.i("Hammerspoon console cleared")
        end,
    },
}

local actionById = {}
local chooser = hs.chooser.new(function(choice)
    if not choice then
        return
    end

    local action = actionById[choice.id]
    if action then
        log.i("Selected " .. action.title)
        hs.timer.doAfter(0, action.action)
    end
end)

kanagawa.styleChooser(chooser, { rows = 12, width = 48 })

local function showServiceManager()
    actionById = {}
    local choices = {}

    for index, action in ipairs(actions) do
        local id = tostring(index)
        actionById[id] = action
        choices[#choices + 1] = {
            id = id,
            text = action.title,
            subText = action.detail,
        }
    end

    chooser:choices(choices)
    chooser:show()
end

M.actions = actions
M.show = showServiceManager

bindings.bind({
    group = "System",
    title = "Service manager",
    modifiers = hyper,
    key = "R",
    action = showServiceManager,
})

log.i("Service manager loaded")

return M
