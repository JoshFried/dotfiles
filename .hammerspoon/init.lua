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
