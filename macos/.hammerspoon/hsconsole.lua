--- Opens and centers the Hammerspoon console for diagnostics.

require("bindings").bind({
    group = "System",
    title = "Hammerspoon console",
    modifiers = { "cmd", "alt" },
    key = "\\",
    action = function()
        hs.openConsole(true)
        hs.timer.doAfter(0.1, function()
            local win = hs.window.find("Hammerspoon Console")
            if win then
                local screen = hs.screen.mainScreen():frame()
                local frame = win:frame()
                frame.x = screen.x + (screen.w - frame.w) / 2
                frame.y = screen.y + (screen.h - frame.h) / 2
                win:setFrame(frame)
            end
        end)
    end,
})
