local cache = {
    launchTimer = nil,
    output = hs.audiodevice.defaultOutputDevice(),
    input = hs.audiodevice.defaultInputDevice(),
}

local outputChooser = hs.chooser.new(function(choice)
    if not choice then
        return
    end

    local idx = choice["idx"]
    local name = choice["text"]

    dev = hs.audiodevice.allOutputDevices()[idx]

    if not dev:setDefaultOutputDevice() then
        hs.alert.show("Unable to enable audio output device " .. name)
    else
        if dev ~= cache.output then
            cache.output = dev
            hs.alert.show("Audio output device is now: " .. name)
        end
    end
end)

local function outSources()
    outputChooser:refreshChoicesCallback()
    outputs = {}
    for i, v in ipairs(hs.audiodevice.allOutputDevices()) do
        print(v:name())
        if not string.find(v:name(), "LG ULTRAGEAR") then
            table.insert(outputs, { text = v:name(), idx = i })
        end
    end

    outputChooser:choices(outputs)
    outputChooser:show()
end

hs.hotkey.bind({ "cmd", "alt" }, "O", function()
    outSources()
end)

local inputChooser = hs.chooser.new(function(choice)
    if not choice then
        return
    end

    local idx = choice["idx"]
    local name = choice["text"]

    dev = hs.audiodevice.allInputDevices()[idx]

    if not dev:setDefaultInputDevice() then
        hs.alert.show("Unable to enable audio output device " .. name)
    else
        if cache.input ~= dev then
            cache.input = dev
            hs.alert.show("Audio output device is now: " .. name)
        end
    end
end)

local function inSources()
    inputChooser:refreshChoicesCallback()

    inputs = {}
    for i, v in ipairs(hs.audiodevice.allInputDevices()) do
        table.insert(inputs, { text = v:name(), idx = i })
    end

    inputChooser:choices(inputs)
    inputChooser:show()
end

hs.hotkey.bind({ "cmd", "alt" }, "I", inSources)

-- This is not exactly a great way to go about this but it works
local headphones = {
    max = "90-9c-4a-e5-cc-ca",
    pro = "00-f3-9f-6a-21-47",
}
local airpods = function(choice)
    local cmd = "/opt/homebrew/bin/blueutil --connect " .. headphones[choice]
    print(cmd)
    hs.osascript.applescript(string.format("do shell script"), cmd)

    cache.launchTimer = hs.timer.doAfter(1.0, function()
        outSources()
    end)
end

hs.hotkey.bind(hyper, "1", function()
    airpods("pro")
end)

hs.hotkey.bind(hyper, "2", function()
    airpods("max")
end)
