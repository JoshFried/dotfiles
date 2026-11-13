local M = {}
M.__index = M

function M.new()
    return setmetatable({ systemMuted = nil, apps = {} }, M)
end

function M:reset()
    self.systemMuted = nil
    self.apps = {}
end

function M:reconcile(device, participants, preferSystem, now)
    local systemMuted = device:inputMuted()
    if type(systemMuted) ~= "boolean" then
        self:reset()
        return
    end

    local active = {}
    local changedMuted = nil
    local joiningMuted = false
    local effectiveStates = {}
    for _, participant in ipairs(participants) do
        local id = participant.id
        active[id] = true
        local previous = self.apps[id]
        local effectiveMuted = participant.muted
        if previous and previous.pending ~= nil then
            if participant.muted == previous.pending then
                previous.pending = nil
                effectiveMuted = previous.muted
            elseif now <= previous.deadline then
                effectiveMuted = previous.muted
            else
                previous.pending = nil
                effectiveMuted = previous.muted or participant.muted
            end
        end
        effectiveStates[id] = effectiveMuted
        if not previous then
            joiningMuted = joiningMuted or participant.muted or participant.muteOnJoin == true
        elseif effectiveMuted ~= previous.muted then
            changedMuted = changedMuted == true or effectiveMuted
        end
    end
    for id in pairs(self.apps) do
        if not active[id] then
            self.apps[id] = nil
        end
    end

    local targetMuted = systemMuted
    if preferSystem then
        targetMuted = systemMuted
    elseif joiningMuted then
        targetMuted = true
    elseif self.systemMuted ~= nil and self.systemMuted ~= systemMuted then
        targetMuted = systemMuted
    elseif changedMuted ~= nil then
        targetMuted = changedMuted
    else
        for _, participant in ipairs(participants) do
            targetMuted = targetMuted or effectiveStates[participant.id]
        end
    end

    if targetMuted ~= systemMuted then
        if device:setInputMuted(targetMuted) then
            systemMuted = targetMuted
        else
            self.systemMuted = systemMuted
            return
        end
    end

    for _, participant in ipairs(participants) do
        local id = participant.id
        local state = self.apps[id] or {}
        local effectiveMuted = effectiveStates[id]
        local pending = state.pending ~= nil and now <= state.deadline
        if effectiveMuted ~= targetMuted or (not pending and participant.muted ~= targetMuted) then
            -- Wait for the app to acknowledge the action before issuing another toggle.
            if not pending then
                local ok, accepted = pcall(participant.toggle)
                if ok and accepted then
                    effectiveMuted = targetMuted
                    state.pending = targetMuted
                    state.deadline = now + 2
                end
            else
                effectiveMuted = targetMuted
            end
        end
        state.muted = effectiveMuted
        self.apps[id] = state
    end
    self.systemMuted = systemMuted
end

return M
