local hotkey = require("hs.hotkey")
local application = require("hs.application")

local cache = {
	launchTimer = nil,
}

function launchOrActivateApp(appName)
	-- first focus with hammerspoon
	local app = hs.application.launchOrFocus(appName)

	-- clear timer if exists
	if cache.launchTimer then
		cache.launchTimer:stop()
	end

	-- wait 1s for window to appear and try hard to show the window
	cache.launchTimer = hs.timer.doAfter(1.0, function()
		local frontmostApp = hs.application.frontmostApplication()
		local frontmostWindows = hs.fnutils.filter(frontmostApp:allWindows(), function(win)
			return win:isStandard()
		end)

		-- break if this app is not frontmost (when/why?)
		if frontmostApp:title() ~= appName then
			log.d("Expected app in front: " .. appName .. " got: " .. frontmostApp:title())
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

hotkey.bind(hyper, "G", function()
	launchOrActivateApp("Google Chrome")
end)

hotkey.bind(hyper, "C", function()
	launchOrActivateApp("CLion")
end)

hotkey.bind(hyper, "T", function()
	launchOrActivateApp("Wezterm")
end)

hotkey.bind(hyper, "J", function()
	launchOrActivateApp("IntelliJ IDEA")
end)

hotkey.bind(hyper, "D", function()
	launchOrActivateApp("Discord")
end)

hotkey.bind(hyper, "S", function()
	launchOrActivateApp("Slack")
end)

hotkey.bind(hyper, "O", function()
	launchOrActivateApp("Microsoft Outlook")
end)
