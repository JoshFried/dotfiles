package.path = "./macos/.hammerspoon/?.lua;" .. package.path

local windows = {}
local timers = {}
local tasks = {}
local moves = {}
local subscriptions = {}
local activeProfile = "office"

local function addWindow(id, bundleID, workspace)
    local window = { windowId = id, bundleID = bundleID, workspace = workspace }
    function window:id()
        return self.windowId
    end
    function window:application()
        return { bundleID = function() return self.bundleID end }
    end
    windows[id] = window
    return window
end

addWindow(1, "com.mitchellh.ghostty", "5")
addWindow(2, "com.mitchellh.ghostty", "6")
addWindow(3, "org.mozilla.firefox", "6")

package.preload.bindings = function()
    return { bind = function() end }
end
package.preload.kanagawa = function()
    return { styleChooser = function() end, showChooser = function() end }
end
package.preload.aerospace = function()
    error("Profiles must not reapply their layout on monitor refresh")
end

hs = {
    settings = {
        get = function() return activeProfile end,
        set = function(_, value) activeProfile = value end,
    },
    alert = { show = function() end },
    printf = function() end,
    chooser = {
        new = function()
            return { choices = function() end }
        end,
    },
    timer = {
        doAfter = function(_, callback)
            local timer = { callback = callback, stopped = false }
            function timer:stop()
                self.stopped = true
            end
            timers[#timers + 1] = timer
            return timer
        end,
    },
    task = {
        new = function(_, callback, arguments)
            local task = { callback = callback, arguments = arguments, running = false }
            function task:start()
                self.running = true
                tasks[#tasks + 1] = self
                return true
            end
            function task:isRunning()
                return self.running
            end
            function task:terminate()
                self.running = false
            end
            return task
        end,
    },
    window = {
        filter = {
            windowCreated = "created",
            windowDestroyed = "destroyed",
            new = function()
                return {
                    getWindows = function()
                        local existing = {}
                        for _, window in pairs(windows) do
                            existing[#existing + 1] = window
                        end
                        return existing
                    end,
                    subscribe = function(_, event, callback)
                        subscriptions[event] = callback
                    end,
                }
            end,
        },
    },
}

local function settle()
    local pendingTimers = timers
    timers = {}
    for _, timer in ipairs(pendingTimers) do
        if not timer.stopped then
            timer.callback()
        end
    end

    while #tasks > 0 do
        local pendingTasks = tasks
        tasks = {}
        for _, task in ipairs(pendingTasks) do
            if task.running then
                task.running = false
                local arguments = task.arguments
                if arguments[1] == "list-windows" then
                    local rows = {}
                    for id, window in pairs(windows) do
                        rows[#rows + 1] =
                            id .. "|" .. window.bundleID .. "|" .. window.workspace
                    end
                    task.callback(0, table.concat(rows, "\n"), "")
                else
                    assert(arguments[1] == "move-node-to-workspace")
                    local id = tonumber(arguments[3])
                    assert(windows[id], "Cannot move a destroyed window")
                    windows[id].workspace = arguments[4]
                    moves[#moves + 1] = id
                    task.callback(0, "", "")
                end
            end
        end
    end
end

local profiles = require("desktopprofiles")
settle()
assert(windows[2].workspace == "6", "Loading the profile moved an existing terminal")
assert(#moves == 0)

subscriptions.created(windows[2])
settle()
assert(windows[2].workspace == "6", "Rediscovering an existing window reset its workspace")

subscriptions.created(addWindow(4, "com.mitchellh.ghostty", "8"))
subscriptions.created(addWindow(5, "com.mitchellh.ghostty", "9"))
settle()
assert(windows[4].workspace == "5" and windows[5].workspace == "5")
assert(windows[2].workspace == "6", "Opening new terminals moved the existing terminal")
assert(#moves == 2, "Only the two new terminals should move")

windows[4].workspace = "7"
subscriptions.created(windows[4])
settle()
assert(windows[4].workspace == "7", "A repeated creation event reset manual placement")

subscriptions.created(addWindow(6, "com.apple.finder", "1"))
settle()
assert(windows[6].workspace == "1" and #moves == 2)

subscriptions.created(addWindow(7, "com.mitchellh.ghostty", "8"))
subscriptions.destroyed(windows[7])
windows[7] = nil
settle()
assert(#moves == 2, "A destroyed window's pending route should be cancelled")

subscriptions.created(addWindow(8, "com.mitchellh.ghostty", "8"))
profiles.apply("personal")
settle()
assert(activeProfile == "personal")
assert(windows[1].workspace == "3" and windows[2].workspace == "3")
assert(windows[3].workspace == "2" and windows[8].workspace == "3")

windows[2].workspace = "9"
profiles.apply("personal")
settle()
assert(windows[2].workspace == "3", "Explicitly selecting a profile should restore its layout")

print("Desktop profile regression checks passed")
