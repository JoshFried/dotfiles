-- Scratchpad terminal (Ghostty) - dropdown style

local function positionScratchpad(win)
    local screen = hs.screen.mainScreen():frame()
    win:setFrame({
        x = screen.x + screen.w * 0.1,
        y = screen.y,
        w = screen.w * 0.8,
        h = screen.h * 0.4
    })
end

local function toggleScratchpad()
    local app = hs.application.get("Ghostty")
    
    if not app then
        hs.application.open("Ghostty")
        hs.timer.doAfter(0.5, function()
            local a = hs.application.get("Ghostty")
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

hs.hotkey.bind(hyper, "Space", toggleScratchpad)
