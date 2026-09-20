--- Protects privacy when leaving the configured home Wi-Fi network.
---
--- The transition minimizes windows and mutes MacBook speakers only when
--- moving away from the home SSID, not during unrelated network changes.

local home = "Josh"

local previous = hs.wifi.currentNetwork()
local wifiMenu = hs.menubar.new()

--- Handles SSID transitions and applies leave-home safeguards.
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
