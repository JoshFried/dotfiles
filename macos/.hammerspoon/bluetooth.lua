local bluetoothChooser = hs.chooser.new(function(choice)
    if not choice then
        return
    end

    local mac = choice["mac"]
    local name = choice["text"]

    hs.task.new("/opt/homebrew/bin/blueutil", function(exitCode, stdOut, stdErr)
        if exitCode == 0 then
            hs.alert.show("Connecting to: " .. name)
        else
            hs.alert.show("Failed to connect to: " .. name)
        end
    end, { "--connect", mac }):start()
end)

local function bluetoothDevices()
    bluetoothChooser:refreshChoicesCallback()

    hs.task.new("/opt/homebrew/bin/blueutil", function(exitCode, stdOut, stdErr)
        local choices = {}

        if exitCode == 0 and stdOut and stdOut ~= "" then
            local output = stdOut:gsub("%%$", "")
            local success, devices = pcall(hs.json.decode, output)

            if success and devices then
                for _, device in ipairs(devices) do
                    table.insert(choices, {
                        text = device.name,
                        mac = device.address
                    })
                end

                -- Sort: AirPods first, then trackpads, then others
                table.sort(choices, function(a, b)
                    local aIsAirPods = string.find(a.text:lower(), "airpods")
                    local bIsAirPods = string.find(b.text:lower(), "airpods")
                    local aIsTrackpad = string.find(a.text:lower(), "trackpad")
                    local bIsTrackpad = string.find(b.text:lower(), "trackpad")

                    if aIsAirPods and not bIsAirPods then return true end
                    if bIsAirPods and not aIsAirPods then return false end
                    if aIsTrackpad and not bIsTrackpad and not bIsAirPods then return true end
                    if bIsTrackpad and not aIsTrackpad and not aIsAirPods then return false end

                    return a.text < b.text
                end)
            end
        end

        bluetoothChooser:choices(choices)
        bluetoothChooser:show()
    end, { "--paired", "--format", "json" }):start()
end

hs.hotkey.bind({ "cmd", "alt" }, "B", bluetoothDevices)
