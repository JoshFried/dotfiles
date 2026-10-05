--- Provides a searchable chooser for toggling paired Bluetooth connections.

local kanagawa = require("kanagawa")

local function normalizedAddress(value)
    if type(value) ~= "string" then
        return nil
    end

    local address = value:upper():gsub("[^0-9A-F]", "")
    if #address == 12 then
        return address
    end
end

local function normalizedName(value)
    if type(value) ~= "string" then
        return nil
    end

    return value:lower():gsub("[^%w]", "")
end

local function batteryPercentage(value)
    if type(value) == "number" and value >= 0 and value <= 100 then
        return math.floor(value + 0.5)
    end

    if type(value) == "string" then
        local percentage = tonumber(value:match("(%d+)%s*%%"))
        if percentage and percentage <= 100 then
            return percentage
        end
    end
end

local function batteryPart(key)
    local lowerKey = key:lower()
    if lowerKey:find("left", 1, true) then
        return "left"
    elseif lowerKey:find("right", 1, true) then
        return "right"
    elseif lowerKey:find("case", 1, true) then
        return "case"
    end

    return "main"
end

local function bluetoothBatteryLevels(output)
    local success, profile = pcall(hs.json.decode, output or "")
    if not success or type(profile) ~= "table" then
        return { byAddress = {}, byName = {} }
    end

    local levels = { byAddress = {}, byName = {} }

    local function visit(value, parentName)
        if type(value) ~= "table" then
            return
        end

        local address
        local name = parentName
        local battery = {}

        for key, field in pairs(value) do
            if type(key) == "string" then
                local lowerKey = key:lower()
                if lowerKey:find("address", 1, true) then
                    address = normalizedAddress(field) or address
                elseif lowerKey == "name" or lowerKey:find("product", 1, true) then
                    name = type(field) == "string" and field or name
                elseif lowerKey:find("battery", 1, true) then
                    local percentage = batteryPercentage(field)
                    if percentage then
                        battery[batteryPart(key)] = percentage
                    end
                end
            end
        end

        if next(battery) then
            if address then
                levels.byAddress[address] = battery
            end

            local nameKey = normalizedName(name)
            if nameKey then
                levels.byName[nameKey] = battery
            end
        end

        for key, field in pairs(value) do
            local childName = parentName
            if type(key) == "string" and type(field) == "table" and not key:match("^_") then
                childName = key
            end
            visit(field, childName)
        end
    end

    visit(profile)
    return levels
end

local function batteryDescription(levels, device)
    local battery = levels.byAddress[normalizedAddress(device.address)]
        or levels.byName[normalizedName(device.name)]
    if not battery then
        return nil
    end

    if battery.left or battery.right or battery.case then
        local parts = {}
        if battery.left then
            parts[#parts + 1] = string.format("L %d%%", battery.left)
        end
        if battery.right then
            parts[#parts + 1] = string.format("R %d%%", battery.right)
        end
        if battery.case then
            parts[#parts + 1] = string.format("Case %d%%", battery.case)
        end
        return table.concat(parts, " · ")
    end

    if battery.main then
        return string.format("Battery %d%%", battery.main)
    end
end

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

    local pairedDevices
    local batteryLevels

    local function showDevices()
        if not pairedDevices or not batteryLevels then
            return
        end

        local choices = {}
        for _, device in ipairs(pairedDevices) do
            local sub
            if device.connected then
                sub = "✓ Connected - select to disconnect"
            else
                sub = "Select to connect"
            end

            local battery = batteryDescription(batteryLevels, device)
            if battery then
                sub = sub .. " · " .. battery
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

        bluetoothChooser:choices(choices)
        bluetoothChooser:show()
    end

    hs.task.new("/opt/homebrew/bin/blueutil", function(exitCode, stdOut, stdErr)
        pairedDevices = {}

        if exitCode == 0 and stdOut and stdOut ~= "" then
            local output = stdOut
            local success, devices = pcall(hs.json.decode, output)
            if success and type(devices) == "table" then
                pairedDevices = devices
            end
        end

        showDevices()
    end, { "--paired", "--format", "json" }):start()

    hs.task.new("/usr/sbin/system_profiler", function(exitCode, stdOut, stdErr)
        if exitCode == 0 then
            batteryLevels = bluetoothBatteryLevels(stdOut)
        else
            batteryLevels = { byAddress = {}, byName = {} }
        end

        showDevices()
    end, { "SPBluetoothDataType", "-json" }):start()
end

require("bindings").bind({
    group = "Devices",
    title = "Bluetooth devices",
    modifiers = { "cmd", "alt" },
    key = "B",
    action = bluetoothDevices,
})
