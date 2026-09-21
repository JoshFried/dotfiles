--- Displays upcoming calendar meetings and opens supported conference links.
---
--- Calendar data comes from an external helper because Hammerspoon does not
--- inherit the terminal's Calendar privacy grant.

local kanagawa = require("kanagawa")

local meetingChooser = nil
local CAL_FILE = "/tmp/cal-events.txt"
local CAL_BIN = os.getenv("HOME") .. "/.config/cal-events"
local calendarTask = nil
local log = hs.logger.new("meeting", "debug")

--- Extracts the first supported conferencing URL from arbitrary event text.
---@param text string
---@return string|nil
local function findMeetingUrl(text)
    local patterns = {
        "https?://[%w%-%.]*zoom%.us/j/[%w%-%._~:/?#@!$&'()*+,;=%%]+",
        "https?://events%.zoom%.us/ej/[%w%-%._~:/?#@!$&'()*+,;=%%]+",
        "https?://[%w%-%.]*chime%.aws/[%w%-%._~:/?#@!$&'()*+,;=%%]+",
        "https?://teams%.microsoft%.com/l/meetup%-join/[%w%-%._~:/?#@!$&'()*+,;=%%]+",
        "https?://meet%.google%.com/[%w%-]+",
    }
    for _, pattern in ipairs(patterns) do
        local url = text:match(pattern)
        if url then return url end
    end
    return nil
end

--- Parses pipe-delimited calendar output into chooser entries.
---@return table[]
local function parseMeetings()
    local f = io.open(CAL_FILE)
    if not f then return {} end
    local content = f:read("*a")
    f:close()

    local choices = {}
    for line in content:gmatch("[^\n]+") do
        local title, time, location, notes = line:match("^(.-)|(.-)|(.-)|(.*)")
        if title and title ~= "" and time and not time:match("12:00AM%-11:59PM") then
            local allText = (location or "") .. " " .. (notes or "")
            local url = findMeetingUrl(allText)
            local sub = time
            if url then sub = sub .. "  🔗" else sub = sub .. "  ⚠ No link" end
            table.insert(choices, { text = title, subText = sub, url = url })
        end
    end
    return choices
end

--- Replaces chooser content with the latest parsed meeting data.
local function updateChooser()
    local choices = parseMeetings()
    if #choices == 0 then
        meetingChooser:choices({ { text = "No upcoming meetings" } })
    else
        meetingChooser:choices(choices)
    end
end

--- Opens the chooser immediately, then refreshes calendar data asynchronously.
local function showMeetings()
    if not meetingChooser then
        meetingChooser = hs.chooser.new(function(choice)
            if not choice then return end
            if choice.url then
                hs.urlevent.openURL(choice.url)
            else
                hs.alert.show("No meeting link found", 1.5)
            end
        end)
        kanagawa.styleChooser(meetingChooser, { rows = 8 })
    end

    meetingChooser:choices({ { text = "Refreshing meetings…" } })
    meetingChooser:show()

    calendarTask = hs.task.new(CAL_BIN, function(exitCode, stdOut, stdErr)
        calendarTask = nil
        if exitCode == 0 then
            local file = io.open(CAL_FILE, "w")
            if file then
                file:write(stdOut or "")
                file:close()
            end
            updateChooser()
            return
        end

        local errorMessage = (stdErr or ""):gsub("%s+$", "")
        if errorMessage == "" then
            errorMessage = "Calendar helper failed with exit code " .. exitCode
        end

        log.e(errorMessage)
        meetingChooser:choices({
            {
                text = "Calendar access required",
                subText = "Allow Full Calendar Access for Hammerspoon in System Settings",
            },
        })
    end)

    if calendarTask then
        calendarTask:start()
    else
        updateChooser()
    end
end

require("bindings").bind({
    group = "Productivity",
    title = "Upcoming meetings",
    modifiers = hyper,
    key = "M",
    action = showMeetings,
})
