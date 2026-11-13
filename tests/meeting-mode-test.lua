package.path = "./macos/.hammerspoon/?.lua;" .. package.path
table.unpack = table.unpack or unpack

local errors = {}
local muted = false
local systemMuted = false
local zoomReads = 0
local zoom = { allWindows = function() return {} end }
local microphone = {
    inputMuted = function() return systemMuted end,
    setInputMuted = function(_, value) systemMuted = value; return true end,
    name = function() return "Microphone" end,
}
local function timer()
    return { stop = function() end }
end
package.preload.slack_huddle = function()
    return {
        read = function()
            return muted, function() muted = not muted; return true end
        end,
        start = function() end,
    }
end
package.preload.bindings = function()
    return { bind = function() end }
end
hs = {
    logger = {
        new = function()
            return { e = function(message) errors[#errors + 1] = message end }
        end,
    },
    audiodevice = {
        defaultInputDevice = function() return microphone end,
        watcher = { setCallback = function() end, start = function() end },
    },
    application = { get = function() return zoom end },
    axuielement = {
        applicationElement = function()
            zoomReads = zoomReads + 1
            error("Inactive Zoom must not be scanned")
        end,
    },
    task = { new = function() return { start = function() end } end },
    timer = { secondsSinceEpoch = function() return 0 end, doAfter = timer, doEvery = timer },
    urlevent = { bind = function() end },
    window = {
        filter = { new = function() return { subscribe = function() end } end },
    },
}

local meeting = require("meeting_mode")
meeting.refreshMicrophoneState()
assert(#errors == 0 and zoomReads == 0, "Idle Zoom is excluded from Slack refreshes")
muted = true
meeting.refreshMicrophoneState()
assert(systemMuted and zoomReads == 0, "Slack mute syncs without scanning idle Zoom")
systemMuted = false
meeting.refreshMicrophoneState()
assert(not muted and zoomReads == 0, "System unmute syncs without scanning idle Zoom")
assert(#errors == 0, table.concat(errors, "\n"))
print("Meeting mode performance regression checks passed")
