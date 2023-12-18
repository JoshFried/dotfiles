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
local hotkey = require "hs.hotkey"

hotkey.bind({"shift"}, "F7", function()
    hs.osascript.applescript(rewindCommand)
end)

hotkey.bind({"shift"}, "F8", function()
    hs.osascript.applescript(playPauseCommand)
end)

hotkey.bind({"shift"}, "F9", function()
    hs.osascript.applescript(fastforwardCommand)
end)
