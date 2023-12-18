local hotkey = require "hs.hotkey"

function reloadConfig(file)
    hs.reload()
    hs.alert.show("Config reloaded")
end

hotkey.bind(hyper, "R", reloadConfig)
