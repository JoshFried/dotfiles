-- AeroSpace helpers via Hammerspoon (for hyper key bindings)

-- Re-assign workspaces when monitors change
local screenWatcher = hs.screen.watcher.new(function()
    hs.timer.doAfter(2, function()
        os.execute(os.getenv("HOME") .. "/.config/aerospace-workspace-assign.sh &")
        hs.timer.doAfter(1, function()
            os.execute("sketchybar --trigger aerospace_workspace_change &")
        end)
    end)
end)
screenWatcher:start()

local aero = "/opt/homebrew/bin/aerospace"

-- Hyper + Tab = toggle between last two workspaces
hs.hotkey.bind(hyper, "tab", function()
    os.execute(aero .. " workspace-back-and-forth &")
end)
