--- Shared Hyper modifier chord supplied by Karabiner-Elements.
---@type string[]
hyper = { "ctrl", "alt", "cmd", "shift" }

local M = {}
local lastChordAt = 0
local chordSuppressionSeconds = 0.35

M.chordWatcher = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
    local flags = event:getFlags()
    if flags.ctrl and flags.alt and flags.cmd and flags.shift then
        lastChordAt = hs.timer.secondsSinceEpoch()
    end

    return false
end):start()

--- Reports whether Hyper was recently used with another key.
---@return boolean
function M.wasChordUsedRecently()
    return hs.timer.secondsSinceEpoch() - lastChordAt < chordSuppressionSeconds
end

return M
