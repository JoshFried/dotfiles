--- Closes an open SketchyBar popup when Escape is pressed.

local M = {}
local stateFile = "/tmp/sketchybar-open-popup"
local closeScript = os.getenv("HOME") .. "/.config/sketchybar/plugins/toggle_popup.sh"

M.escapeWatcher = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
    if event:getKeyCode() ~= hs.keycodes.map.escape or not hs.fs.attributes(stateFile) then
        return false
    end

    M.closeTask = hs.task.new("/bin/bash", function()
        M.closeTask = nil
    end, { closeScript, "close" })

    if M.closeTask then
        M.closeTask:start()
    else
        os.remove(stateFile)
    end

    return true
end):start()

return M
