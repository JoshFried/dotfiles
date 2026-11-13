local M = {}
local BUNDLE_ID = "com.tinyspeck.slackmacgap"
local log = hs.logger.new("slack_huddle", "warning")
local audioButton = nil
local observer = nil
local observedPID = nil
local refreshTimer = nil
local activeTimer = nil
local previousMuted = nil
local previousSystemMuted = nil
local running = false
local lastDiscoveryAt = nil
local discoveryTimer = nil
local onChange = nil
local refresh = nil

local function buttonState(element)
    if not element or element.AXRole ~= "AXButton" or element.AXEnabled == false then
        return nil
    end
    for _, attribute in ipairs({ "AXDescription", "AXTitle", "AXHelp" }) do
        local text = (element[attribute] or ""):lower()
        if text:match("^unmute microphone") or text:match("^unmute your microphone") then
            return true
        end
        if text:match("^mute microphone") or text:match("^mute your microphone") then
            return false
        end
    end
end

local function findAudioButton(element, depth, budget)
    if not element or depth > 30 or budget.remaining <= 0 then
        return nil, nil
    end
    budget.remaining = budget.remaining - 1
    local muted = buttonState(element)
    if muted ~= nil then
        return muted, element
    end
    for _, child in ipairs(element.AXChildren or {}) do
        local childMuted, button = findAudioButton(child, depth + 1, budget)
        if button then
            return childMuted, button
        end
    end
    return nil, nil
end

function M.read()
    local slack = hs.application.get(BUNDLE_ID)
    if not slack then
        audioButton = nil
        return nil, nil
    end
    local muted = nil
    if audioButton and audioButton:isValid() then
        muted = buttonState(audioButton)
    end
    if muted == nil then
        local now = hs.timer.secondsSinceEpoch()
        if lastDiscoveryAt and now - lastDiscoveryAt < 3 then
            audioButton = nil
            if running and not discoveryTimer then
                discoveryTimer = hs.timer.doAfter(3 - (now - lastDiscoveryAt), function()
                    discoveryTimer = nil
                    refresh()
                end)
            end
            return nil, nil
        end
        lastDiscoveryAt = now
        local root = hs.axuielement.applicationElement(slack)
        muted, audioButton = findAudioButton(root, 0, { remaining = 6000 })
    end
    if not audioButton then
        return nil, nil
    end

    local button = audioButton
    local pid = slack:pid()
    return muted, function()
        local currentSlack = hs.application.get(BUNDLE_ID)
        if not currentSlack or currentSlack:pid() ~= pid
            or not button:isValid() or buttonState(button) ~= muted
        then
            return false
        end
        -- Slack can acknowledge AXPress without toggling its huddle microphone.
        local ok = pcall(hs.eventtap.keyStroke, { "cmd", "shift" }, "space", 0, currentSlack)
        return ok
    end
end

local function scheduleRefresh()
    if not running then return end
    if refreshTimer then
        refreshTimer:stop()
    end
    refreshTimer = hs.timer.doAfter(0.15, function()
        refreshTimer = nil
        refresh()
    end)
end

local function stopObserver()
    if observer then
        observer:stop()
        observer = nil
    end
    observedPID = nil
    audioButton = nil
    lastDiscoveryAt = nil
end

local function addWatcher(element, notification)
    if element then
        pcall(function()
            observer:addWatcher(element, notification)
        end)
    end
end

local function ensureObserver()
    local slack = hs.application.get(BUNDLE_ID)
    if not slack then
        stopObserver()
        return
    end
    if observer and observedPID == slack:pid() then
        return
    end
    stopObserver()
    local ok, created = pcall(hs.axuielement.observer.new, slack:pid())
    if not ok then
        log.w("Unable to observe Slack accessibility events: " .. tostring(created))
        return
    end
    observer = created
    observedPID = slack:pid()
    observer:callback(function(_, _, notification)
        if notification == "AXUIElementDestroyed" then
            audioButton = nil
        end
        scheduleRefresh()
    end)
    local root = hs.axuielement.applicationElement(slack)
    for _, notification in ipairs({
        "AXFocusedUIElementChanged", "AXFocusedWindowChanged", "AXWindowCreated",
    }) do
        addWatcher(root, notification)
    end
    local started, err = pcall(function() observer:start() end)
    if not started then
        log.w("Unable to start Slack accessibility observer: " .. tostring(err))
        stopObserver()
    end
end

refresh = function()
    if not running then return end
    ensureObserver()
    local previousButton = audioButton
    local muted = M.read()
    if audioButton ~= previousButton and observer then
        for _, notification in ipairs({ "AXValueChanged", "AXTitleChanged", "AXUIElementDestroyed" }) do
            addWatcher(audioButton, notification)
        end
    end
    if muted ~= nil and not activeTimer then
        -- Electron can change its mute label without an accessibility notification.
        activeTimer = hs.timer.doEvery(1, function()
            local ok, err = xpcall(refresh, debug.traceback)
            if not ok then log.e("Slack huddle refresh failed: " .. err) end
        end)
    elseif muted == nil and activeTimer then
        activeTimer:stop()
        activeTimer = nil
    end
    local device = hs.audiodevice.defaultInputDevice()
    local systemMuted = device and device:inputMuted()
    if muted ~= previousMuted or systemMuted ~= previousSystemMuted
        or (muted ~= nil and type(systemMuted) == "boolean" and muted ~= systemMuted)
    then
        previousMuted = muted
        previousSystemMuted = systemMuted
        onChange()
    end
end

function M.start(callback)
    onChange = callback
    if hs.settings.get("slackHuddleAutomaticSync") == false then
        return
    end
    running = true
    M.applicationWatcher = hs.application.watcher.new(function(name, event, app)
        if name == "Slack" or (app and event ~= hs.application.watcher.terminated
            and app:bundleID() == BUNDLE_ID) or event == hs.application.watcher.terminated
        then
            scheduleRefresh()
        end
    end):start()
    M.presenceTimer = hs.timer.doEvery(60, refresh)
    refresh()
end

function M.stop()
    running = false
    for _, timer in pairs({ refreshTimer, activeTimer, discoveryTimer, M.presenceTimer }) do
        timer:stop()
    end
    refreshTimer = nil
    activeTimer = nil
    discoveryTimer = nil
    if M.applicationWatcher then M.applicationWatcher:stop() end
    stopObserver()
end

return M
