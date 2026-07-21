local kanagawa = require("kanagawa")

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
kanagawa.styleChooser(outputChooser)

local function outSources()
    outputChooser:refreshChoicesCallback()
    local outputs = {}
    local currentOutput = hs.audiodevice.defaultOutputDevice()
    local currentName = currentOutput and currentOutput:name() or ""

    for i, v in ipairs(hs.audiodevice.allOutputDevices()) do
        if not string.find(v:name(), "LG ULTRAGEAR") then
            local sub = ""
            if v:name() == currentName then
                sub = "✓ Active"
            end
            table.insert(outputs, { text = v:name(), subText = sub, idx = i })
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
        hs.alert.show("Unable to enable audio input device " .. name)
    else
        if cache.input ~= dev then
            cache.input = dev
            hs.alert.show("Audio input device is now: " .. name)
        end
    end
end)
kanagawa.styleChooser(inputChooser)

local function inSources()
    inputChooser:refreshChoicesCallback()
    local inputs = {}
    local currentInput = hs.audiodevice.defaultInputDevice()
    local currentName = currentInput and currentInput:name() or ""

    for i, v in ipairs(hs.audiodevice.allInputDevices()) do
        local sub = ""
        if v:name() == currentName then
            sub = "✓ Active"
        end
        table.insert(inputs, { text = v:name(), subText = sub, idx = i })
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
    local res = hs.execute("/opt/homebrew/bin/blueutil --connect " .. headphones[choice])

    cache.launchTimer = hs.timer.doAfter(1.0, function()
        outSources()
    end)
end
