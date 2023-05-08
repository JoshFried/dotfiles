local hotkey = require("hs.hotkey")
local window = require("hs.window")
local screen = require("hs.screen")
local spaces = require("hs.spaces")

local function handleCenter(win, screenFrame)
	local winFrame = win:frame()
	winFrame.h = screenFrame.h / 2
	winFrame.w = screenFrame.w * 0.75
	winFrame.x = screenFrame.x + (screenFrame.w - winFrame.w) / 2
	winFrame.y = screenFrame.y + (screenFrame.h - winFrame.h) / 2
	win:setFrame(winFrame)
	win:centerOnScreen()
	win:focus()
end

local function centered(app)
	local application = hs.application.find(app)
	local mainScreen = screen.mainScreen()
	local focusedWindow = window.focusedWindow()
	local mainFrame = mainScreen:frame()
	local focusedSpace = spaces.focusedSpace()
	local handled = false

	if application then
		local existingWindows = application:allWindows()

		for _, win in ipairs(existingWindows) do
			if handled then
				return
			end

			if win:screen() ~= mainScreen then
				win:moveToScreen(mainScreen)
			end

			handleCenter(win, mainFrame)
			handled = true
		end

		if handled then
			return
		end
	end

	local launch = LaunchOrActivateApp(app)

	if launch then
		local application = hs.application.get(app)
		local window = application:getWindow()
		spaces.moveWindowToSpace(window, focusedSpace)
		handleCenter(focusedWindow, mainFrame)
	end
end

hotkey.bind({ "cmd", "ctrl" }, "e", function()
	centered("Messages")
end)
hotkey.bind({ "cmd", "ctrl" }, "A", function()
	centered("Apple Music")
end)
hotkey.bind({ "cmd", "ctrl" }, "P", function()
	centered("Podcasts")
end)

hotkey.bind({ "cmd", "ctrl" }, "W", function()
	centered("Notes")
end)
