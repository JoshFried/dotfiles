--- Sends one low-battery notification per threshold during each discharge cycle.

local thresholds = { 20, 15, 10, 5 }
local notified = {}

local alertStyle = {
    fillColor = { red = 0.89, green = 0.41, blue = 0.46, alpha = 0.95 },
    strokeColor = { red = 0.09, green = 0.08, blue = 0.11, alpha = 1 },
    textColor = { red = 0.09, green = 0.08, blue = 0.11, alpha = 1 },
    textFont = ".AppleSystemUIFontBold",
    textSize = 30,
    radius = 12,
    fadeInDuration = 0.15,
    fadeOutDuration = 0.4,
    atScreenEdge = 0,
}

--- Displays a persistent low-battery notification.
---@param pct number Current battery percentage.
local function alert(pct)
    local urgency = pct <= 10 and "CRITICAL BATTERY" or "LOW BATTERY"

    hs.alert.show(
        string.format("%s\n%d%% remaining - plug in now", urgency, pct),
        alertStyle,
        hs.screen.mainScreen(),
        pct <= 10 and 12 or 8
    )

    hs.notify.new({
        title = urgency,
        informativeText = string.format("%d%% remaining. Plug in soon.", pct),
        soundName = pct <= 5 and "Funk" or "Glass",
        withdrawAfter = 0,
    }):send()
end

--- Evaluates battery state and resets threshold history while charging.
local function check()
    local pct = hs.battery.percentage()
    local charging = hs.battery.isCharging() or hs.battery.powerSource() == "AC Power"

    if charging then
        notified = {}
        return
    end

    local crossedThreshold = false
    for _, t in ipairs(thresholds) do
        if pct <= t and not notified[t] then
            notified[t] = true
            crossedThreshold = true
        end
    end

    if crossedThreshold then
        alert(pct)
    end
end

local watcher = hs.battery.watcher.new(check)
watcher:start()
check()

return watcher
