local rewindCommand = [[
tell application "Music" to back track
]]

local playPauseCommand = [[
tell application "Music" to playpause
]]

local fastforwardCommand = [[
tell application "Music" to next track
]]

-- Then, we'll use Hammerspoon to bind the F7, F8, and F9 keys to these commands:
local bindings = require("bindings")

local controls = {
    { key = "F7", title = "Previous track", command = rewindCommand },
    { key = "F8", title = "Play or pause", command = playPauseCommand },
    { key = "F9", title = "Next track", command = fastforwardCommand },
}

for _, control in ipairs(controls) do
    bindings.bind({
        group = "Media",
        title = control.title,
        modifiers = { "shift" },
        key = control.key,
        action = function()
            hs.osascript.applescript(control.command)
        end,
    })
end
