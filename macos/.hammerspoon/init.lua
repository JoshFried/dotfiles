require("hs.ipc")
hs.caffeinate.set("displayIdle", true, true)

local function awake()
    hs.caffeinate.set("displayIdle", true, true)
end

hs.caffeinate.watcher.new(awake):start()

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
