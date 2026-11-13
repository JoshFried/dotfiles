--- Synchronizes system, Zoom, and Slack mute and controls Zoom camera shortcuts.

local M = {}
local log = hs.logger.new("meeting_mode", "warning")
local microphoneWatcher = nil
local refreshTimer = nil
local meetingWindowFilter = nil
local meetingWindowRefreshTimer = nil
local meetingSafetyTimer = nil
local meetingBurstTimers = {}
local zoomObserver = nil
local zoomObserverRefreshTimer = nil
local zoomObserverRestartTimer = nil
local meetingActive = false
local reconcileMicrophoneState = nil
local reconcileZoomCameraState = nil
local microphoneSync = require("microphone_sync").new()
local slackHuddle = require("slack_huddle")
local SKETCHYBAR = "/opt/homebrew/bin/sketchybar"
local ZOOM_BUNDLE_ID = "us.zoom.xos"
local microphoneState = {
    systemMuted = nil,
    zoomMuted = nil,
}
local zoomCameraOn = nil

--- Publishes the current input-device state to SketchyBar.
local function publishMicrophoneState()
    local device = hs.audiodevice.defaultInputDevice()
    local muted = device and device:inputMuted() or false
    local deviceName = device and device:name() or "No input device"

    hs.task.new(SKETCHYBAR, nil, {
        "--trigger",
        "microphone_change",
        "MUTED=" .. tostring(muted),
        "DEVICE=" .. deviceName,
    }):start()
end

--- Publishes Zoom's active-meeting camera state to SketchyBar.
---@param active boolean
---@param cameraOn? boolean
local function publishZoomCameraState(active, cameraOn)
    hs.task.new(SKETCHYBAR, nil, {
        "--trigger",
        "zoom_camera_change",
        "ACTIVE=" .. tostring(active),
        "CAMERA_ON=" .. tostring(cameraOn == true),
    }):start()
end

--- Debounces audio-device notifications before publishing the resulting state.
local function scheduleMicrophoneRefresh()
    if refreshTimer then
        refreshTimer:stop()
    end

    refreshTimer = hs.timer.doAfter(0.25, function()
        refreshTimer = nil
        reconcileMicrophoneState()
    end)
end

--- Finds a nested application menu item by title.
---@param items table[]
---@param targetTitle string
---@param parentPath? string[]
---@return string[]|nil
local function findMenuPath(items, targetTitle, parentPath)
    local path = parentPath or {}

    for _, item in ipairs(items or {}) do
        local title = item.AXTitle
        if title and title ~= "" then
            local itemPath = { table.unpack(path) }
            itemPath[#itemPath + 1] = title

            if title == targetTitle and item.AXEnabled ~= false then
                return itemPath
            end

            local childPath = findMenuPath(item.AXChildren, targetTitle, itemPath)
            if childPath then
                return childPath
            end
        end
    end
end

--- Finds Zoom's primary meeting audio button in its accessibility tree.
---@param element hs.axuielement
---@param depth? integer
---@return boolean|nil
---@return hs.axuielement|nil
local function findZoomAudioButton(element, depth)
    if not element or (depth or 0) > 8 then
        return nil, nil
    end

    local description = (element.AXDescription or ""):lower()
    local title = (element.AXTitle or ""):lower()
    local role = element.AXRole
    local enabled = element.AXEnabled

    if role == "AXButton" and enabled ~= false then
        if description == "unmute my audio" then
            return true, element
        end
        if description == "mute my audio" then
            return false, element
        end
    end

    if role == "AXMenuItem" and enabled ~= false then
        if title == "unmute audio" or title == "unmute my audio" then
            return true, element
        end
        if title == "mute audio" or title == "mute my audio" then
            return false, element
        end
    end

    for _, child in ipairs(element.AXChildren or {}) do
        local muted, button = findZoomAudioButton(child, (depth or 0) + 1)
        if button then
            return muted, button
        end
    end

    return nil, nil
end

--- Finds Zoom's primary meeting video button in its accessibility tree.
---@param element hs.axuielement
---@param depth? integer
---@return boolean|nil
---@return hs.axuielement|nil
local function findZoomVideoButton(element, depth)
    if not element or (depth or 0) > 8 then
        return nil, nil
    end

    local description = (element.AXDescription or ""):lower()
    local role = element.AXRole
    local enabled = element.AXEnabled

    if role == "AXButton" and enabled ~= false then
        if description == "stop video" then
            return true, element
        end
        if description == "start video" then
            return false, element
        end
    end

    for _, child in ipairs(element.AXChildren or {}) do
        local cameraOn, button = findZoomVideoButton(child, (depth or 0) + 1)
        if button then
            return cameraOn, button
        end
    end

    return nil, nil
end

--- Infers Zoom mute state from persistent meeting accessibility metadata.
---@param element hs.axuielement
---@param depth? integer
---@return boolean|nil
local function inferZoomMicrophoneState(element, depth)
    if not element or (depth or 0) > 8 then
        return nil
    end

    local description = (element.AXDescription or ""):lower()
    local title = (element.AXTitle or ""):lower()

    if description:find("computer audio muted", 1, true) or title == "unmute audio" then
        return true
    end
    if description:find("computer audio unmuted", 1, true) or title == "mute audio" then
        return false
    end

    for _, child in ipairs(element.AXChildren or {}) do
        local muted = inferZoomMicrophoneState(child, (depth or 0) + 1)
        if muted ~= nil then
            return muted
        end
    end
end

--- Infers Zoom camera state from persistent meeting accessibility metadata.
---@param element hs.axuielement
---@param depth? integer
---@return boolean|nil
local function inferZoomCameraState(element, depth)
    if not element or (depth or 0) > 8 then
        return nil
    end

    local title = (element.AXTitle or ""):lower()
    if title == "stop video" then
        return true
    end
    if title == "start video" then
        return false
    end

    for _, child in ipairs(element.AXChildren or {}) do
        local cameraOn = inferZoomCameraState(child, (depth or 0) + 1)
        if cameraOn ~= nil then
            return cameraOn
        end
    end
end

--- Reports whether Zoom currently owns a visible meeting window.
---@param zoom hs.application
---@return boolean
local function zoomMeetingActive(zoom)
    for _, window in ipairs(zoom:allWindows()) do
        if window:isVisible() and window:title():find("Zoom Meeting", 1, true) then
            return true
        end
    end
    return false
end

--- Returns Zoom's current meeting mute state and the action that toggles it.
---@return boolean|nil
---@return fun(): boolean|nil
local function zoomMicrophoneState()
    local zoom = hs.application.get(ZOOM_BUNDLE_ID)
    if not zoom then
        return nil, nil
    end

    local applicationElement = hs.axuielement.applicationElement(zoom)
    local accessibilityMuted, audioButton = findZoomAudioButton(applicationElement)
    if audioButton then
        return accessibilityMuted, function()
            local ok, accepted = pcall(function()
                return audioButton:performAction("AXPress")
            end)
            return ok and accepted and true or false
        end
    end

    local menuItems = zoom:getMenuItems() or {}
    local mutedTitles = { "Unmute Audio", "Unmute My Audio" }
    local liveTitles = { "Mute Audio", "Mute My Audio" }

    for _, title in ipairs(mutedTitles) do
        local path = findMenuPath(menuItems, title)
        if path then
            return true, function()
                return zoom:selectMenuItem(path)
            end
        end
    end

    for _, title in ipairs(liveTitles) do
        local path = findMenuPath(menuItems, title)
        if path then
            return false, function()
                return zoom:selectMenuItem(path)
            end
        end
    end

    local inferredMuted = inferZoomMicrophoneState(applicationElement)
    if inferredMuted ~= nil and zoomMeetingActive(zoom) then
        return inferredMuted, function()
            hs.eventtap.keyStroke({ "cmd", "shift" }, "a", 0, zoom)
            return true
        end
    end

    if zoomMeetingActive(zoom) and microphoneState.zoomMuted ~= nil then
        return microphoneState.zoomMuted, function()
            hs.eventtap.keyStroke({ "cmd", "shift" }, "a", 0, zoom)
            return true
        end
    end

    return nil, nil
end

--- Returns Zoom's current meeting camera state and the action that toggles it.
---@return boolean|nil
---@return fun(): boolean|nil
local function zoomCameraState()
    local zoom = hs.application.get(ZOOM_BUNDLE_ID)
    if not zoom then
        return nil, nil
    end

    local applicationElement = hs.axuielement.applicationElement(zoom)
    local cameraOn, videoButton = findZoomVideoButton(applicationElement)
    if videoButton then
        return cameraOn, function()
            local ok = pcall(function()
                videoButton:performAction("AXPress")
            end)
            return ok
        end
    end

    local inferredCameraOn = inferZoomCameraState(applicationElement)
    if inferredCameraOn ~= nil and zoomMeetingActive(zoom) then
        return inferredCameraOn, function()
            hs.eventtap.keyStroke({ "cmd", "shift" }, "v", 0, zoom)
            return true
        end
    end

    local menuItems = zoom:getMenuItems() or {}
    local stopVideoPath = findMenuPath(menuItems, "Stop Video")
    if stopVideoPath then
        return true, function()
            return zoom:selectMenuItem(stopVideoPath)
        end
    end

    local startVideoPath = findMenuPath(menuItems, "Start Video")
    if startVideoPath then
        return false, function()
            return zoom:selectMenuItem(startVideoPath)
        end
    end

    if zoomMeetingActive(zoom) and zoomCameraOn ~= nil then
        return zoomCameraOn, function()
            hs.eventtap.keyStroke({ "cmd", "shift" }, "v", 0, zoom)
            return true
        end
    end

    return nil, nil
end

--- Reconciles active calls without unmuting when a muted call joins.
---@param preferSystem? boolean
reconcileMicrophoneState = function(preferSystem)
    local device = hs.audiodevice.defaultInputDevice()
    if not device then
        microphoneSync:reset()
        microphoneState.systemMuted = nil
        microphoneState.zoomMuted = nil
        publishMicrophoneState()
        return
    end

    local zoomMuted, toggleZoomMicrophone = nil, nil
    if meetingActive then
        zoomMuted, toggleZoomMicrophone = zoomMicrophoneState()
    end
    local slackMuted, toggleSlackMicrophone = slackHuddle.read()
    local previousSystemMuted = microphoneState.systemMuted
    local participants = {}
    if zoomMuted ~= nil then
        participants[#participants + 1] = {
            id = "zoom", muted = zoomMuted, toggle = toggleZoomMicrophone, muteOnJoin = true,
        }
    end
    if slackMuted ~= nil then
        participants[#participants + 1] = {
            id = "slack", muted = slackMuted, toggle = toggleSlackMicrophone,
        }
    end
    microphoneSync:reconcile(device, participants, preferSystem, hs.timer.secondsSinceEpoch())
    microphoneState.systemMuted = device:inputMuted()
    local zoomState = microphoneSync.apps.zoom
    microphoneState.zoomMuted = zoomState and zoomState.muted
    if previousSystemMuted ~= microphoneState.systemMuted then
        publishMicrophoneState()
    end
end

--- Refreshes SketchyBar when Zoom's active camera state changes.
reconcileZoomCameraState = function()
    local cameraOn = zoomCameraState()
    if cameraOn == nil then
        if zoomCameraOn ~= nil then
            zoomCameraOn = nil
            publishZoomCameraState(false)
        end
        return
    end

    if cameraOn ~= zoomCameraOn then
        zoomCameraOn = cameraOn
        publishZoomCameraState(true, cameraOn)
    end
end

--- Toggles mute on the current input device and active Zoom and Slack calls.
local function toggleMicrophone()
    local device = hs.audiodevice.defaultInputDevice()
    if not device then
        hs.alert.show("No microphone available", 1.5)
        publishMicrophoneState()
        return
    end

    local muted = not device:inputMuted()
    if not device:setInputMuted(muted) then
        hs.alert.show("Unable to change microphone mute", 1.5)
        publishMicrophoneState()
        return
    end

    hs.alert.show(muted and "Microphone muted" or "Microphone live", 1)
    reconcileMicrophoneState(true)
end

--- Toggles video in Zoom without changing the frontmost application.
local function toggleZoomCamera()
    local zoom = hs.application.get(ZOOM_BUNDLE_ID)
    if not zoom then
        hs.alert.show("Zoom is not running", 1.5)
        return
    end

    local cameraOn, toggleCamera = zoomCameraState()
    if toggleCamera and toggleCamera() then
        hs.alert.show(cameraOn and "Zoom camera off" or "Zoom camera on", 1)
        hs.timer.doAfter(0.5, reconcileZoomCameraState)
        return
    end

    hs.eventtap.keyStroke({ "cmd", "shift" }, "v", 0, zoom)
    hs.alert.show("Toggled Zoom camera", 1)
end

hs.urlevent.bind("toggle-microphone", toggleMicrophone)
hs.urlevent.bind("microphone-status", publishMicrophoneState)
hs.urlevent.bind("toggle-zoom-camera", toggleZoomCamera)
hs.urlevent.bind("zoom-camera-status", function()
    zoomCameraOn = nil
    local cameraOn = zoomCameraState()
    publishZoomCameraState(cameraOn ~= nil, cameraOn)
    zoomCameraOn = cameraOn
end)

require("bindings").bind({
    group = "Meetings",
    title = "Toggle microphone mute",
    modifiers = { "cmd", "alt", "ctrl", "shift" },
    key = "M",
    apps = { "zoom.us", "Zoom Workplace", "us.zoom.xos", "Slack", "com.tinyspeck.slackmacgap" },
    keywords = { "zoom", "slack", "huddle", "mic", "mute", "unmute" },
    action = toggleMicrophone,
})

require("bindings").bind({
    group = "Meetings",
    title = "Toggle Zoom camera",
    modifiers = { "cmd", "alt", "ctrl", "shift" },
    key = "C",
    apps = { "zoom.us", "Zoom Workplace", "us.zoom.xos" },
    keywords = { "zoom", "camera", "video" },
    action = toggleZoomCamera,
})

microphoneWatcher = hs.audiodevice.watcher
microphoneWatcher.setCallback(scheduleMicrophoneRefresh)
microphoneWatcher.start()

local function refreshMicrophoneState()
    M.lastMicrophoneRefreshAt = hs.timer.secondsSinceEpoch()
    local microphoneOk, microphoneError = xpcall(reconcileMicrophoneState, debug.traceback)
    if not microphoneOk then
        log.e("Microphone reconciliation failed: " .. microphoneError)
    end
end

local function refreshCameraState()
    M.lastCameraRefreshAt = hs.timer.secondsSinceEpoch()
    local cameraOk, cameraError = xpcall(reconcileZoomCameraState, debug.traceback)
    if not cameraOk then
        log.e("Camera reconciliation failed: " .. cameraError)
    end
end

local function refreshMeetingState()
    refreshMicrophoneState()
    refreshCameraState()
end

local function scheduleZoomStateRefresh()
    if zoomObserverRefreshTimer then
        zoomObserverRefreshTimer:stop()
    end

    zoomObserverRefreshTimer = hs.timer.doAfter(0.15, function()
        zoomObserverRefreshTimer = nil
        if meetingActive then
            refreshMeetingState()
        end
    end)
end

local function addZoomWatcher(observer, element, notification)
    if not element then
        return
    end

    local ok = pcall(function()
        observer:addWatcher(element, notification)
    end)
    if not ok then
        log.d("Zoom does not expose " .. notification .. " for this accessibility element")
    end
end

local function stopZoomObserver()
    if zoomObserverRestartTimer then
        zoomObserverRestartTimer:stop()
        zoomObserverRestartTimer = nil
    end

    if zoomObserver then
        zoomObserver:stop()
        zoomObserver = nil
    end
end

local function startZoomObserver(zoom)
    stopZoomObserver()

    local created, observer = pcall(hs.axuielement.observer.new, zoom:pid())
    if not created then
        log.w("Unable to observe Zoom accessibility events: " .. tostring(observer))
        return
    end

    local applicationElement = hs.axuielement.applicationElement(zoom)
    local _, audioButton = findZoomAudioButton(applicationElement)
    local _, videoButton = findZoomVideoButton(applicationElement)

    observer:callback(function(_, _, notification)
        if notification == "AXUIElementDestroyed" then
            if zoomObserverRestartTimer then
                zoomObserverRestartTimer:stop()
            end
            zoomObserverRestartTimer = hs.timer.doAfter(0.25, function()
                zoomObserverRestartTimer = nil
                local currentZoom = hs.application.get(ZOOM_BUNDLE_ID)
                if meetingActive and currentZoom then
                    startZoomObserver(currentZoom)
                end
            end)
        end
        scheduleZoomStateRefresh()
    end)

    addZoomWatcher(observer, applicationElement, "AXFocusedUIElementChanged")
    addZoomWatcher(observer, applicationElement, "AXFocusedWindowChanged")
    addZoomWatcher(observer, applicationElement, "AXWindowCreated")

    for _, button in pairs({ audioButton, videoButton }) do
        addZoomWatcher(observer, button, "AXValueChanged")
        addZoomWatcher(observer, button, "AXTitleChanged")
        addZoomWatcher(observer, button, "AXUIElementDestroyed")
    end

    local started, startError = pcall(function()
        observer:start()
    end)
    if not started then
        log.w("Unable to start Zoom accessibility observer: " .. tostring(startError))
        return
    end

    zoomObserver = observer
end

local function scheduleMeetingRefreshBurst()
    for _, timer in ipairs(meetingBurstTimers) do
        timer:stop()
    end
    meetingBurstTimers = {}

    for _, delay in ipairs({ 0, 1, 3 }) do
        meetingBurstTimers[#meetingBurstTimers + 1] = hs.timer.doAfter(delay, refreshMeetingState)
    end
end

local function checkMeetingPresence()
    local zoom = hs.application.get(ZOOM_BUNDLE_ID)
    local active = zoom ~= nil and zoomMeetingActive(zoom)

    if active and not meetingActive then
        meetingActive = true
        microphoneState.zoomMuted = nil
        zoomCameraOn = nil
        startZoomObserver(zoom)
        scheduleMeetingRefreshBurst()
    elseif not active and meetingActive then
        meetingActive = false
        stopZoomObserver()
        microphoneSync.apps.zoom = nil
        microphoneState.zoomMuted = nil
        zoomCameraOn = nil
        publishZoomCameraState(false)
    end
end

local function scheduleMeetingPresenceCheck()
    if meetingWindowRefreshTimer then
        meetingWindowRefreshTimer:stop()
    end

    meetingWindowRefreshTimer = hs.timer.doAfter(0.25, function()
        meetingWindowRefreshTimer = nil
        checkMeetingPresence()
    end)
end

meetingWindowFilter = hs.window.filter.new("zoom.us")
meetingWindowFilter:subscribe({
    hs.window.filter.windowCreated,
    hs.window.filter.windowDestroyed,
    hs.window.filter.windowVisible,
    hs.window.filter.windowNotVisible,
    hs.window.filter.windowTitleChanged,
}, scheduleMeetingPresenceCheck)

meetingSafetyTimer = hs.timer.doEvery(60, function()
    if meetingActive then
        refreshMeetingState()
    end
end)

M.meetingWindowFilter = meetingWindowFilter
M.meetingSafetyTimer = meetingSafetyTimer
M.refreshMeetingState = refreshMeetingState
M.refreshMicrophoneState = refreshMicrophoneState
M.refreshCameraState = refreshCameraState

slackHuddle.start(refreshMicrophoneState)
checkMeetingPresence()
publishMicrophoneState()

return M
