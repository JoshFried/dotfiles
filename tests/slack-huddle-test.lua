-- Supply synthetic Slack accessibility elements so huddle detection and mute
-- handling can run without Slack or macOS permissions.

package.path = "./macos/.hammerspoon/?.lua;" .. package.path

local app = nil
local timers = {}
local observers = {}
local changed = 0
local appCallback = nil
local rootReads = 0
local keyboardActions = 0
local clock = 0
local systemMuted = false
local automaticSync = nil

local function timer(callback)
    local value = { callback = callback }
    function value:stop() self.stopped = true end
    timers[#timers + 1] = value
    return value
end

local function button(description)
    local value = { AXRole = "AXButton", AXDescription = description, AXEnabled = true, valid = true }
    function value:isValid() return self.valid end
    function value:performAction(action)
        error("Slack AXPress must not be used: it can succeed without changing mute state")
    end
    return value
end

local function slack(root, pid)
    local value = { root = root, processId = pid }
    function value:pid() return self.processId end
    function value:bundleID() return "com.tinyspeck.slackmacgap" end
    return value
end

hs = {
    settings = { get = function() return automaticSync end },
    logger = { new = function() return { w = function() end, e = function() end } end },
    application = {
        get = function(id)
            assert(id == "com.tinyspeck.slackmacgap")
            return app
        end,
        watcher = {
            terminated = "terminated",
            new = function(callback)
                appCallback = callback
                return { start = function(self) return self end, stop = function() end }
            end,
        },
    },
    axuielement = {
        applicationElement = function(application)
            rootReads = rootReads + 1
            return application.root
        end,
        observer = {
            new = function(pid)
                local value = { pid = pid, watchers = {} }
                function value:callback(callback) self.handler = callback end
                function value:addWatcher(element, notification)
                    self.watchers[#self.watchers + 1] = { element, notification }
                end
                function value:start() return self end
                function value:stop() self.stopped = true end
                observers[#observers + 1] = value
                return value
            end,
        },
    },
    timer = {
        secondsSinceEpoch = function() return clock end,
        doAfter = function(_, callback) return timer(callback) end,
        doEvery = function(seconds, callback)
            local value = timer(callback)
            value.interval = seconds
            return value
        end,
    },
    audiodevice = {
        defaultInputDevice = function()
            return { inputMuted = function() return systemMuted end }
        end,
    },
    eventtap = {
        keyStroke = function(modifiers, key, delay, target)
            assert(modifiers[1] == "cmd" and modifiers[2] == "shift" and key == "space")
            assert(delay == 0 and target == app, "The shortcut is delivered to Slack")
            if target.reject then error("Unable to deliver shortcut") end
            keyboardActions = keyboardActions + 1
            local value = target.microphone
            value.AXDescription = value.AXDescription:match("^Unmute")
                and "Mute microphone" or "Unmute microphone"
        end,
    },
}

local function settle()
    local pending = timers
    timers = {}
    for _, value in ipairs(pending) do
        if not value.stopped and not value.interval then
            clock = clock + 3
            value.callback()
        end
        if value.interval then timers[#timers + 1] = value end
    end
end

local function pollActive()
    for _, value in ipairs(timers) do
        if value.interval == 1 and not value.stopped then
            value.callback()
            return
        end
    end
    error("No active-huddle fallback timer")
end

local microphone = button("Mute microphone")
local nested = { AXChildren = { microphone } }
for _ = 1, 20 do nested = { AXChildren = { nested } } end
app = slack({ AXChildren = { button("Mute notifications"), nested } }, 100)
app.microphone = microphone
local module = require("slack_huddle")
module.start(function() changed = changed + 1 end)
assert(changed == 1, "An active huddle is discovered at startup")
local muted, toggle = module.read()
assert(muted == false, "Slack's mute action means the microphone is live")
local reads = rootReads
module.read()
assert(rootReads == reads, "Active huddles reuse the cached control")
assert(toggle() and keyboardActions == 1, "The native shortcut toggles the huddle")
pollActive()
assert(changed == 2 and module.read() == true, "Polling catches a mute without AX notifications")
microphone.AXDescription = "Mute your microphone (⌘⇧M)"
observers[1].handler(nil, microphone, "AXTitleChanged")
settle()
assert(changed == 3 and module.read() == false, "Accessibility events catch Slack unmute")
app.reject = true
local _, rejectedToggle = module.read()
assert(not rejectedToggle(), "Rejected keyboard actions report failure")
app.reject = false
microphone.valid = false
app.root = { AXChildren = { button("Mute notifications") } }
observers[1].handler(nil, microphone, "AXUIElementDestroyed")
settle()
assert(changed == 4 and module.read() == nil, "Leaving a huddle clears its state")
assert(not toggle(), "A stale control cannot be pressed after the huddle ends")
for _, value in ipairs(timers) do
    assert(value.interval ~= 1 or value.stopped, "Fallback polling stops outside huddles")
end

local newMicrophone = button("Unmute microphone")
app = slack({ AXChildren = { newMicrophone } }, 200)
app.microphone = newMicrophone
appCallback("Slack", "launched", app)
settle()
assert(observers[1].stopped and observers[2].pid == 200, "Slack restart replaces its observer")
assert(module.read() == true and changed >= 5, "Restart discovers the new huddle")
newMicrophone.AXEnabled = false
pollActive()
assert(module.read() == nil, "Disabled controls are unavailable")
app = nil
appCallback(nil, "terminated", nil)
settle()
assert(observers[2].stopped and module.read() == nil, "Slack exit releases its observer")

local lastMicrophone = button("Mute microphone")
app = slack({ AXChildren = { lastMicrophone } }, 300)
app.microphone = lastMicrophone
appCallback("Slack", "launched", app)
settle()
local beforePoll = changed
pollActive()
assert(changed == beforePoll, "Steady-state polling avoids full reconciliation")
systemMuted = true
pollActive()
assert(changed == beforePoll + 1, "System mute changes still reconcile without AX events")
pollActive()
assert(changed == beforePoll + 2, "A mismatch is retried until Slack acknowledges the action")
local _, staleToggle = module.read()
lastMicrophone.AXDescription = "Unmute microphone"
assert(not staleToggle(), "A changed control is resampled before another toggle")
module.stop()
beforePoll = changed
settle()
assert(changed == beforePoll, "Stopping cancels pending callbacks")
for _, value in ipairs(timers) do
    assert(value.stopped, "Stopping cancels background timers")
end
automaticSync = false
beforePoll = changed
module.start(function() changed = changed + 1 end)
settle()
assert(changed == beforePoll, "The saved pause setting prevents background sync at startup")
assert(module.read() == true, "Manual controls remain available while background sync is paused")

print("Slack huddle adapter tests passed")
