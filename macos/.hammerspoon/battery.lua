-- Low battery notifications.
-- Warns at 20% and 10%, plus a critical alert at 5%. Suppresses when charging.
-- State is kept so we only notify once per threshold per discharge cycle.

local thresholds = { 20, 10, 5 }
local notified = {}

local function alert(pct)
    hs.notify.new({
        title = "Battery Low",
        informativeText = string.format("%d%% remaining. Plug in soon.", pct),
        soundName = pct <= 5 and "Funk" or "Glass",
        withdrawAfter = 0,
    }):send()
end

local function check()
    local pct = hs.battery.percentage()
    local charging = hs.battery.isCharging() or hs.battery.powerSource() == "AC Power"

    if charging then
        notified = {} -- reset once plugged in
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
