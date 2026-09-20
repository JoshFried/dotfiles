--- Hammerspoon entry point and module lifecycle coordinator.
---
--- Loads core bindings first, isolates module failures, and allows the
--- machine-specific `work` module to be absent.

require("hs.ipc")
hs.caffeinate.set("displayIdle", true, true)

--- Reasserts the display-idle preference after system power-state changes.
local function awake()
    hs.caffeinate.set("displayIdle", true, true)
end

hs.caffeinate.watcher.new(awake):start()

--- Loads a module while keeping unrelated automation available after failures.
---@param name string Module name passed to `require`.
---@param optional? boolean Suppress user-visible errors when the module is absent.
local function loadModule(name, optional)
    local ok, err = pcall(require, name)
    if not ok and not optional then
        hs.notify.new({
            title = "Hammerspoon module failed",
            informativeText = name .. ": " .. tostring(err),
        }):send()
    end
end

loadModule("hyper")
loadModule("bindings")

local modules = {
    "launchoractivateapp",
    "media",
    "hsreload",
    "caffeine",
    "centeredapp",
    "wifi_watcher",
    "soundswitch",
    "cycleapp",
    "fullscreen",
    "bluetooth",
    "wifiswitch",
    "hsconsole",
    "newspace",
    "scratchpad",
    "battery",
    "aerospace",
    "meeting",
    "windowchooser",
    "services",
}

for _, module in ipairs(modules) do
    loadModule(module)
end

local bindings = require("bindings")
bindings.bind({
    group = "Productivity",
    title = "Clipboard history",
    modifiers = hyper,
    key = "V",
    action = function()
        hs.urlevent.openURL("raycast://extensions/raycast/clipboard-history/clipboard-history")
    end,
})

loadModule("work", true)
loadModule("commandpalette")
