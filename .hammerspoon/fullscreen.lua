local function toggle()
    local window = hs.window.focusedWindow()

    if window ~= nil then
        window:setFullScreen(not window:isFullScreen())
    end
end

hs.hotkey.bind(hyper, "A", toggle)
