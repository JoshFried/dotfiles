local hotkey = require("hs.hotkey")
local applications = require("hs.application")
local fnutils = require("hs.fnutils")

local cache = {
    launchTimer = nil,
}

local function launchOrActivateApp(appName)
    local curr = applications.frontmostApplication()
    local name = curr:name()
    if name == appName then
        cycle()
        return
    end
    -- first focus with hammerspoon
    local app = applications.launchOrFocus(appName)

    -- clear timer if exists
    if cache.launchTimer then
        cache.launchTimer:stop()
    end

    -- wait 1s for window to appear and try hard to show the window
    cache.launchTimer = hs.timer.doAfter(1.0, function()
        local frontmostApp = applications.frontmostApplication()
        local frontmostWindows = fnutils.filter(frontmostApp:allWindows(), function(win)
            return win:isStandard()
        end)

        -- break if this app is not frontmost (when/why?)
        if frontmostApp:title() ~= appName then
            -- log.d("Expected app in front: " .. appName .. " got: " .. frontmostApp:title())
            return
        end

        if #frontmostWindows == 0 then
            -- check if there's app name in window menu (Calendar, Messages, etc...)
            if frontmostApp:findMenuItem({ "Window", appName }) then
                -- select it, usually moves to space with this window
                frontmostApp:selectMenuItem({ "Window", appName })
            else
                -- otherwise send cmd-n to create new window
                hs.eventtap.keyStroke({ "cmd" }, "n")
            end
        end
    end)

    return app
end

local apps = {
    { key = "G", app = "Google Chrome" },
    { key = "T", app = "Wezterm" },
    { key = "D", app = "Discord" },
    { key = "S", app = "Slack" },
    { key = "O", app = "Microsoft Outlook" },
    { key = "C", app = "Amazon Chime" },
}

for _, mappings in ipairs(apps) do
    hotkey.bind(hyper, mappings.key, function()
        launchOrActivateApp(mappings.app)
    end)
end
