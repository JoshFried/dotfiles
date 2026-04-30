local wifiChooser = hs.chooser.new(function(choice)
    if not choice then return end
    local ssid = choice["text"]
    hs.execute("networksetup -setairportnetwork en0 '" .. ssid .. "'")
    hs.alert.show("Connecting to: " .. ssid)
end)

local function getKnownNetworks()
    local known = {}
    local output, status = hs.execute("networksetup -listpreferredwirelessnetworks en0")
    if status then
        for ssid in output:gmatch("\t([^\n]+)") do
            known[ssid] = true
        end
    end
    return known
end

local function wifiNetworks()
    wifiChooser:choices({})
    wifiChooser:show()

    local known = getKnownNetworks()
    local current = hs.wifi.currentNetwork() or ""
    local networks = hs.wifi.availableNetworks() or {}

    local choices = {}
    local seen = {}

    for _, ssid in ipairs(networks) do
        if not seen[ssid] and ssid ~= "" then
            seen[ssid] = true
            local sub = ""
            if ssid == current then
                sub = "✓ Connected"
            elseif known[ssid] then
                sub = "Known network"
            end
            table.insert(choices, {
                text = ssid,
                subText = sub,
                isConnected = (ssid == current),
                isKnown = known[ssid] or false
            })
        end
    end

    -- Sort: connected first, then known, then alphabetical
    table.sort(choices, function(a, b)
        if a.isConnected and not b.isConnected then return true end
        if b.isConnected and not a.isConnected then return false end
        if a.isKnown and not b.isKnown then return true end
        if b.isKnown and not a.isKnown then return false end
        return a.text < b.text
    end)

    wifiChooser:choices(choices)
end

hs.hotkey.bind({ "cmd", "alt" }, "W", wifiNetworks)
