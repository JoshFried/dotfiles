-- Meeting picker: shows upcoming meetings, select one to join
-- Uses cal-events binary via a wrapper that writes to a temp file
-- (workaround for Hammerspoon TCC sandbox not having calendar access)

local meetingChooser = nil
local CAL_FILE = "/tmp/cal-events.txt"
local CAL_BIN = os.getenv("HOME") .. "/.config/cal-events"

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
    end

    -- Read cached calendar file (refreshed by .zshrc on terminal open)
    local choices = parseMeetings()
    if #choices == 0 then
        meetingChooser:choices({{ text = "No upcoming meetings", subText = "Open a terminal to refresh" }})
    else
        meetingChooser:choices(choices)
    end
    meetingChooser:show()
end

hs.hotkey.bind(hyper, "M", showMeetings)
