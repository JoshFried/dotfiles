require("hs.ipc")
hs.caffeinate.set("displayIdle", true, true)

function awake()
    hs.caffeinate.set("displayIdle", true, true)
end

hs.caffeinate.watcher.new(awake):start()

require("hyper")
require("launchoractivateapp")
require("media")
require("hsreload")
require("caffeine")
require("centeredapp")
require("wifi_watcher")
require("soundswitch")
require("cycleapp")
require("fullscreen")
require("bluetooth")
require("wifiswitch")
require("hsconsole")
require("newspace")
require("scratchpad")
require("battery")
require("aerospace")


-- Raycast clipboard history
hs.hotkey.bind(hyper, "V", function()
    hs.urlevent.openURL("raycast://extensions/raycast/clipboard-history/clipboard-history")
end)

-- Work-specific bindings (gitignored, only loaded if present)
pcall(require, "work")
