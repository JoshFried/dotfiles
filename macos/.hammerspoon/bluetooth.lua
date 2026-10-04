--- Provides a searchable chooser for toggling paired Bluetooth connections.

local kanagawa = require("kanagawa")

local bluetoothChooser = hs.chooser.new(function(choice)
    if not choice then
        return
    end

    local mac = choice["mac"]
    local name = choice["text"]
    local isConnected = choice["isConnected"]
    local option = isConnected and "--disconnect" or "--connect"
    local successMessage = isConnected and "Disconnected from: " or "Connected to: "
    local failureMessage = isConnected and "Failed to disconnect from: " or "Failed to connect to: "

    hs.task.new("/opt/homebrew/bin/blueutil", function(exitCode, stdOut, stdErr)
        if exitCode == 0 then
            hs.alert.show(successMessage .. name)
        else
            hs.alert.show(failureMessage .. name)
        end
    end, { option, mac }):start()
end)
kanagawa.styleChooser(bluetoothChooser)

--- Refreshes, prioritizes, and displays paired Bluetooth devices.
local function bluetoothDevices()
    bluetoothChooser:refreshChoicesCallback()

    hs.task.new("/opt/homebrew/bin/blueutil", function(exitCode, stdOut, stdErr)
        local choices = {}

        if exitCode == 0 and stdOut and stdOut ~= "" then
            local output = stdOut:gsub("%%$", "")
            local success, devices = pcall(hs.json.decode, output)

            if success and devices then
                for _, device in ipairs(devices) do
                    local sub = ""
                    if device.connected then
                        sub = "✓ Connected - select to disconnect"
                    else
                        sub = "Select to connect"
                    end
                    table.insert(choices, {
                        text = device.name,
                        subText = sub,
                        mac = device.address,
                        isConnected = device.connected or false
                    })
                end

                table.sort(choices, function(a, b)
                    if a.isConnected and not b.isConnected then return true end
                    if b.isConnected and not a.isConnected then return false end

                    local aIsAirPods = string.find(a.text:lower(), "airpods")
                    local bIsAirPods = string.find(b.text:lower(), "airpods")
                    local aIsTrackpad = string.find(a.text:lower(), "trackpad")
                    local bIsTrackpad = string.find(b.text:lower(), "trackpad")

                    if aIsAirPods and not bIsAirPods then return true end
                    if bIsAirPods and not aIsAirPods then return false end
                    if aIsTrackpad and not bIsTrackpad then return true end
                    if bIsTrackpad and not aIsTrackpad then return false end

                    return a.text < b.text
                end)
            end
        end

        bluetoothChooser:choices(choices)
        bluetoothChooser:show()
    end, { "--paired", "--format", "json" }):start()
end

require("bindings").bind({
    group = "Devices",
    title = "Bluetooth devices",
    modifiers = { "cmd", "alt" },
    key = "B",
    action = bluetoothDevices,
})
