function cycle()
    local application = hs.application.frontmostApplication()
    local frontmostWindow = hs.window.frontmostWindow()
    local launchApps = application:name()
    local runningApps = hs.application.runningApplications()
    local runningWindows = {}

    launchApps = type(launchApps) == "table" and launchApps or { launchApps }

    -- filter running applications by apps array
    local runningApps = hs.fnutils.map(launchApps, function(launchApp)
        return hs.application.get(launchApp)
    end)

    -- create table of sorted windows per application
    hs.fnutils.each(runningApps, function(runningApp)
        local standardWindows = hs.fnutils.filter(runningApp:allWindows(), function(win)
            return win:isStandard()
        end)

        -- sort by id, so windows don't jump randomly every time
        table.sort(standardWindows, function(a, b)
            return a:id() < b:id()
        end)

        -- concat with all running windows
        hs.fnutils.concat(runningWindows, standardWindows)
    end)

    if #runningApps == 0 then
        -- if no apps are running then launch first one in list
        launchOrActivateApp(launchApps[1])
    elseif #runningWindows == 0 then
        -- if some apps are running, but no windows - force create one
        launchOrActivateApp(runningApps[1]:title())
    else
        -- check if one of windows is already focused
        local currentIndex = hs.fnutils.indexOf(runningWindows, frontmostWindow)

        if not currentIndex then
            -- if none of them is selected focus the first one
            runningWindows[1]:focus()
        else
            -- otherwise cycle through all the windows
            local newIndex = currentIndex + 1
            if newIndex > #runningWindows then
                newIndex = 1
            end

            runningWindows[newIndex]:focus()
        end

        highlightWindow()
    end
end

local cache = {}
local module = { cache = cache }

-- returns 'graphite' or 'aqua'
local getOSXAppearance = function()
    local _, res = hs.applescript.applescript([[
    tell application "System Events"
      tell appearance preferences
        return appearance as string
      end tell
    end tell
  ]])

    return res
end

local getHighlightWindowColor = function()
    local blueColor = { red = 50 / 255, green = 138 / 255, blue = 215 / 255, alpha = 1.0 }
    local grayColor = { red = 143 / 255, green = 143 / 255, blue = 143 / 255, alpha = 1.0 }

    return getOSXAppearance() == "graphite" and grayColor or blueColor
end

function highlightWindow()
    local borderWidth = 6
    local fadeTime = 0.25
    local stickTime = 0.5
    local focusedWindow = hs.window.focusedWindow()

    if not cache.borderDrawing then
        cache.borderDrawing = hs.drawing
            .rectangle({ x = 0, y = 0, w = 0, h = 0 })
            :setFill(nil)
            :setStroke(true)
            :setStrokeWidth(borderWidth)
            :setStrokeColor(getHighlightWindowColor())
            :setAlpha(0.75)
    end

    if not focusedWindow then
        cache.borderDrawing:delete()
        cache.borderDrawing = nil

        return
    end

    local isFullScreen = focusedWindow:isFullScreen()
    local frame = focusedWindow:frame()

    if isFullScreen then
        cache.borderDrawing:setFrame(frame):setRoundedRectRadii(0, 0)
    else
        cache.borderDrawing
            :setFrame({
                x = frame.x - borderWidth / 2 - 1,
                y = frame.y - borderWidth / 2 - 1,
                w = frame.w + borderWidth + 2,
                h = frame.h + borderWidth + 2,
            })
            :setRoundedRectRadii(borderWidth, borderWidth)
    end

    cache.borderDrawing:show(fadeTime)

    if cache.borderDrawingFadeOut then
        cache.borderDrawingFadeOut:stop()
    end

    cache.borderDrawingFadeOut = hs.timer.doAfter(stickTime, function()
        cache.borderDrawing:hide(fadeTime)
        cache.borderDrawingFadeOut = nil
    end)
end

local hotkey = require("hs.hotkey")

hotkey.bind({ "cmd", "alt" }, "C", function()
    cycle()
end)
