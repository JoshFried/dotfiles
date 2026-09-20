local kanagawa = require("kanagawa")

local cache = {
    launchTimer = nil,
    output = hs.audiodevice.defaultOutputDevice(),
    input = hs.audiodevice.defaultInputDevice(),
}

local function findDevice(devices, name)
    for _, device in ipairs(devices) do
        if device:name() == name then
            return device
        end
    end
end

local outputChooser = hs.chooser.new(function(choice)
    if not choice then
        return
    end

    local name = choice["text"]
    local dev = findDevice(hs.audiodevice.allOutputDevices(), name)

    if not dev or not dev:setDefaultOutputDevice() then
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

    for _, v in ipairs(hs.audiodevice.allOutputDevices()) do
        if not string.find(v:name(), "LG ULTRAGEAR") then
            local sub = ""
            if v:name() == currentName then
                sub = "✓ Active"
            end
            table.insert(outputs, { text = v:name(), subText = sub })
        end
    end

    outputChooser:choices(outputs)
    outputChooser:show()
end

require("bindings").bind({
    group = "Devices",
    title = "Audio output",
    modifiers = { "cmd", "alt" },
    key = "O",
    action = outSources,
})

local inputChooser = hs.chooser.new(function(choice)
    if not choice then
        return
    end

    local name = choice["text"]
    local dev = findDevice(hs.audiodevice.allInputDevices(), name)

    if not dev or not dev:setDefaultInputDevice() then
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

    for _, v in ipairs(hs.audiodevice.allInputDevices()) do
        local sub = ""
        if v:name() == currentName then
            sub = "✓ Active"
        end
        table.insert(inputs, { text = v:name(), subText = sub })
    end

    inputChooser:choices(inputs)
    inputChooser:show()
end

require("bindings").bind({
    group = "Devices",
    title = "Audio input",
    modifiers = { "cmd", "alt" },
    key = "I",
    action = inSources,
})
