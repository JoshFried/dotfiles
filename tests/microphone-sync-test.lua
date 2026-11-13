package.path = "./macos/.hammerspoon/?.lua;" .. package.path
local Sync = require("microphone_sync")

local function device(muted)
    return {
        muted = muted,
        inputMuted = function(self) return self.muted end,
        setInputMuted = function(self, value)
            if self.fail then return false end
            self.muted = value
            return true
        end,
    }
end

local function call(id, muted, delayed)
    local participant = { id = id, muted = muted, toggles = 0, muteOnJoin = id == "zoom" }
    participant.toggle = function()
        participant.toggles = participant.toggles + 1
        if participant.fail then return false end
        if not delayed then participant.muted = not participant.muted end
        return true
    end
    return participant
end

local sync = Sync.new()
local input = device(false)
local slack = call("slack", false)
sync:reconcile(input, { slack }, false, 0)
assert(not input.muted and slack.toggles == 0, "A live huddle keeps its initial live state")
slack.muted = true
sync:reconcile(input, { slack }, false, 1)
assert(input.muted and slack.toggles == 0, "Slack mute updates the system")
slack.muted = false
sync:reconcile(input, { slack }, false, 2)
assert(not input.muted, "Slack unmute updates the system")
input.muted = true
sync:reconcile(input, { slack }, true, 3)
assert(slack.muted and slack.toggles == 1, "The bar or hotkey updates Slack")
sync:reconcile(input, { slack }, false, 4)
input.muted = false
sync:reconcile(input, { slack }, false, 5)
assert(not slack.muted, "An audio-device mute change updates Slack")

sync = Sync.new()
input = device(false)
slack = call("slack", false, true)
sync:reconcile(input, { slack }, false, 0)
input.muted = true
sync:reconcile(input, { slack }, true, 1)
sync:reconcile(input, { slack }, true, 1.2)
assert(input.muted and slack.toggles == 1, "Pending actions are not sent twice")
input.muted = false
sync:reconcile(input, { slack }, true, 1.3)
assert(not input.muted and slack.toggles == 1, "Rapid reversal waits for the first action")
slack.muted = true
sync:reconcile(input, { slack }, false, 1.4)
assert(not input.muted and slack.toggles == 2, "Acknowledgement applies the queued reversal")
slack.muted = false
sync:reconcile(input, { slack }, false, 1.5)
assert(not input.muted and slack.toggles == 2, "Reversal acknowledgement stays live")

sync = Sync.new()
input = device(false)
slack = call("slack", false, true)
sync:reconcile(input, { slack }, false, 0)
input.muted = true
sync:reconcile(input, { slack }, true, 1)
sync:reconcile(input, { slack }, false, 4)
assert(input.muted and slack.toggles == 2, "An unacknowledged mute cannot unmute the system")

sync = Sync.new()
input = device(false)
slack = call("slack", false)
local zoom = call("zoom", false)
sync:reconcile(input, { zoom, slack }, false, 0)
assert(input.muted and zoom.muted and slack.muted, "Zoom keeps its muted-on-join policy")
sync:reconcile(input, { zoom, slack }, false, 1)
slack.muted = false
sync:reconcile(input, { zoom, slack }, false, 2)
assert(not input.muted and not zoom.muted, "Slack unmute propagates to Zoom")
sync:reconcile(input, { zoom, slack }, false, 3)
zoom.muted = true
sync:reconcile(input, { zoom, slack }, false, 4)
assert(input.muted and slack.muted, "Zoom mute propagates to Slack")
sync:reconcile(input, { zoom, slack }, false, 5)
input.muted = false
sync:reconcile(input, { zoom, slack }, true, 6)
assert(not slack.muted and not zoom.muted, "An explicit unmute overrides both calls")
sync:reconcile(input, { zoom, slack }, false, 7)
zoom.muted = true
sync:reconcile(input, { zoom, slack }, false, 8)
sync:reconcile(input, {}, false, 9)
assert(input.muted and next(sync.apps) == nil, "Leaving calls does not unmute the system")

sync = Sync.new()
input = device(false)
slack = call("slack", true)
input.fail = true
sync:reconcile(input, { slack }, false, 0)
assert(slack.muted and slack.toggles == 0, "Device failures cannot unmute a muted call")
input.fail = false
sync:reconcile(input, { slack }, false, 1)
assert(input.muted, "Synchronization recovers when the device becomes writable")

sync = Sync.new()
input = device(false)
slack = call("slack", false)
sync:reconcile(input, { slack }, false, 0)
input.muted = true
slack.fail = true
sync:reconcile(input, { slack }, true, 1)
assert(sync.apps.slack.pending == nil, "Rejected actions are not recorded as successful")
slack.fail = false
sync:reconcile(input, { slack }, false, 2)
assert(input.muted and slack.muted, "Synchronization retries a rejected action")
sync:reset()
assert(sync.systemMuted == nil and next(sync.apps) == nil, "Missing devices clear state")

print("Microphone synchronization tests passed")
