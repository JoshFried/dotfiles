local home = "Josh"

local previous = hs.wifi.currentNetwork()
local wifiMenu = hs.menubar.new()

function ssidChangedCallback()
    local current = hs.wifi.currentNetwork()

    windows = hs.window.allWindows()
    outputs = hs.audiodevice.allOutputDevices()
    local mbp = "MacBook Pro Speakers"
    local device = hs.audiodevice.findOutputByName(mbp)

    if previous ~= home then
        previous = current
        return
    end

    if current ~= home then
        currentSsid = current

        for i, window in pairs(windows) do
            window:minimize()
        end

        device:setMuted(true)
    end
end

wifiWatcher = hs.wifi.watcher.new(ssidChangedCallback)
wifiWatcher:start()
ssidChangedCallback()
