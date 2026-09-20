--- Toggles WezTerm as a centered dropdown-style scratchpad.

--- Applies the scratchpad frame on the main screen.
---@param win hs.window
local function positionScratchpad(win)
    local screen = hs.screen.mainScreen():frame()
    win:setFrame({
        x = screen.x + screen.w * 0.1,
        y = screen.y,
        w = screen.w * 0.8,
        h = screen.h * 0.4
    })
end

--- Launches, reveals, or hides the WezTerm scratchpad.
local function toggleScratchpad()
    local app = hs.application.get("WezTerm")
    
    if not app then
        hs.application.open("WezTerm")
        hs.timer.doAfter(0.5, function()
            local a = hs.application.get("WezTerm")
            if a and a:mainWindow() then
                positionScratchpad(a:mainWindow())
            end
        end)
        return
    end
    
    local win = app:mainWindow()
    
    if app:isHidden() or (win and not win:isVisible()) then
        app:unhide()
        app:activate()
        if win then
            positionScratchpad(win)
            win:focus()
        end
    else
        app:hide()
    end
end

require("bindings").bind({
    group = "Applications",
    title = "WezTerm scratchpad",
    modifiers = hyper,
    key = "Space",
    action = toggleScratchpad,
})
