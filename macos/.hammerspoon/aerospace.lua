-- AeroSpace helpers via Hammerspoon (for hyper key bindings)

local aero = "/opt/homebrew/bin/aerospace"

-- Hyper + Tab = toggle between last two workspaces
hs.hotkey.bind(hyper, "tab", function()
    os.execute(aero .. " workspace-back-and-forth &")
end)
