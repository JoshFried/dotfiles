local function toggle()
    local window = hs.window.focusedWindow()

    if window ~= nil then
        window:setFullScreen(not window:isFullScreen())
    end
end

require("bindings").bind({
    group = "Windows",
    title = "Toggle fullscreen",
    modifiers = hyper,
    key = "A",
    action = toggle,
})
