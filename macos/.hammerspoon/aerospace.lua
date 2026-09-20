--- Keeps AeroSpace workspace placement and SketchyBar indicators synchronized.

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

require("bindings").bind({
    group = "Workspaces",
    title = "Previous workspace",
    modifiers = hyper,
    key = "Tab",
    action = function()
        os.execute(aero .. " workspace-back-and-forth &")
    end,
})
