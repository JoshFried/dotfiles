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

    hs.task.new("/usr/sbin/system_profiler", function(exitCode, stdOut, stdErr)
        local choices = {}
        local seen = {}

        local inNetworkList = false
        local currentSSID = nil
        local currentSignal = 0

        for line in stdOut:gmatch("[^\r\n]+") do
            if line:match("Other Local Wi%-Fi Networks:") then
                inNetworkList = true
            elseif inNetworkList then
                local ssid = line:match("^%s+([^:]+):$")
                if ssid and not ssid:match("PHY Mode") and not ssid:match("Channel") and not ssid:match("Security") and not ssid:match("Signal") then
                    if currentSSID and not seen[currentSSID] then
                        seen[currentSSID] = true
                        table.insert(choices, {
                            text = currentSSID,
                            subText = known[currentSSID] and "Known network" or ("Signal: " .. currentSignal .. "%"),
                            signal = currentSignal,
                            isKnown = known[currentSSID] or false
                        })
                    end
                    currentSSID = ssid:gsub("^%s+", ""):gsub("%s+$", "")
                    currentSignal = 0
                end

                local signal = line:match("Signal / Noise:%s*(-?%d+)")
                if signal then
                    -- Convert dBm to percentage (roughly -30 = 100%, -90 = 0%)
                    currentSignal = math.max(0, math.min(100, (tonumber(signal) + 90) * 100 / 60))
                end

                if line:match("^%S") and not line:match("Other Local") then
                    inNetworkList = false
                end
            end
        end

        -- Add last network
        if currentSSID and not seen[currentSSID] then
            seen[currentSSID] = true
            table.insert(choices, {
                text = currentSSID,
                subText = known[currentSSID] and "Known network" or ("Signal: " .. math.floor(currentSignal) .. "%"),
                signal = currentSignal,
                isKnown = known[currentSSID] or false
            })
        end

        -- Sort: known networks first, then by signal strength
        table.sort(choices, function(a, b)
            if a.isKnown and not b.isKnown then return true end
            if b.isKnown and not a.isKnown then return false end
            return a.signal > b.signal
        end)

        wifiChooser:choices(choices)
    end, { "SPAirPortDataType" }):start()
end

hs.hotkey.bind({ "cmd", "alt" }, "W", wifiNetworks)
