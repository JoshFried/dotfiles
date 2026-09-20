--- Application launcher that cycles existing windows and repairs windowless launches.

local bindings = require("bindings")
local applications = require("hs.application")
local fnutils = require("hs.fnutils")

local cache = {
	launchTimer = nil,
}

--- Focuses an application, cycles it when frontmost, or creates a missing window.
---@param appName string Display name used by Hammerspoon.
---@return boolean|nil launched Whether Hammerspoon accepted the launch request.
function launchOrActivateApp(appName)
	local curr = applications.frontmostApplication()
	local name = curr:name()

	if name == appName then
		cycle()
		return
	end

	local app = applications.launchOrFocus(appName)

	if appName == "IntelliJ IDEA" then
		app = applications.launchOrFocusByBundleID("com.jetbrains.intellij")
	end

	if cache.launchTimer then
		cache.launchTimer:stop()
	end

	cache.launchTimer = hs.timer.doAfter(1.0, function()
		local frontmostApp = applications.frontmostApplication()
		local frontmostWindows = fnutils.filter(frontmostApp:allWindows(), function(win)
			return win:isStandard()
		end)

		if frontmostApp:title() ~= appName then
			return
		end

		if #frontmostWindows == 0 then
			if frontmostApp:findMenuItem({ "Window", appName }) then
				frontmostApp:selectMenuItem({ "Window", appName })
			else
				hs.eventtap.keyStroke({ "cmd" }, "n")
			end
		end
	end)

	return app
end

local apps = {
	{ key = "G", app = "Google Chrome" },
	{ key = "T", app = "Ghostty" },
	-- { key = "T", app = "WezTerm" },
	{ key = "D", app = "Discord" },
	{ key = "S", app = "Slack" },
	{ key = "O", app = "Microsoft Outlook" },
	{ key = "C", app = "Codex" },
	{ key = "I", app = "IntelliJ IDEA" },
	{ key = "F", app = "Firefox" },
	{ key = "Z", app = "zoom.us" },
	{ key = "Q", app = "KeyCastr" },
	{ key = "P", app = "Docker" },
}

for _, mappings in ipairs(apps) do
    bindings.bind({
        group = "Applications",
        title = mappings.app,
        modifiers = hyper,
        key = mappings.key,
        action = function()
            if mappings.app == "Firefox" then
                hs.timer.doAfter(0.05, function()
                    launchOrActivateApp(mappings.app)
                end)
            else
                launchOrActivateApp(mappings.app)
            end
        end,
    })
end
