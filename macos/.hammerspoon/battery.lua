--- Sends one low-battery notification per threshold during each discharge cycle.

local thresholds = { 20, 10, 5 }
local notified = {}

--- Displays a persistent low-battery notification.
---@param pct number Current battery percentage.
local function alert(pct)
    hs.notify.new({
        title = "Battery Low",
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

    for _, t in ipairs(thresholds) do
        if pct <= t and not notified[t] then
            notified[t] = true
            alert(pct)
        end
    end
end

hs.battery.watcher.new(check):start()
