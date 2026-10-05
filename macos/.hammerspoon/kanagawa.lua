--- Kanagawa palette and consistent styling for Hammerspoon choosers.
---
--- Chooser font selection is not exposed by Hammerspoon; this module controls
--- colors, dimensions, search behavior, and post-show centering.

---@class ChooserStyleOptions
---@field rows? integer Number of visible result rows.
---@field width? number Chooser width as a percentage of the screen.
---@field searchSubText? boolean Include secondary text in search.
---@field vcenter? boolean Center the chooser after it appears.
---@field title? string Label displayed in the chooser search field.

local M = {}
local styledChoosers = {}
local showRequestId = 0

---@type table<string, string>
M.palette = {
    sumiInk0     = "#16161D", -- deep background
    sumiInk3     = "#1F1F28", -- background
    sumiInk4     = "#2A2A37", -- light background
    sumiInk5     = "#363646", -- lighter bg / borders
    fujiWhite    = "#DCD7BA", -- foreground
    oldWhite     = "#C8C093", -- dim foreground
    crystalBlue  = "#7E9CD8", -- accent / active
    springGreen  = "#98BB6C",
    waveRed      = "#E46876",
    carpYellow   = "#E6C384",
    oniViolet    = "#957FB8",
    surimiOrange = "#FFA066",
    katanaGray   = "#727169", -- comments / inactive
}

--- Converts a hexadecimal color into a Hammerspoon color table.
---@param hex string `#RRGGBB` color value.
---@return table
local function hexToRgb(hex)
    hex = hex:gsub("#", "")
    return {
        red   = tonumber(hex:sub(1, 2), 16) / 255,
        green = tonumber(hex:sub(3, 4), 16) / 255,
        blue  = tonumber(hex:sub(5, 6), 16) / 255,
        alpha = 1.0,
    }
end

M.rgb = hexToRgb

--- Applies reusable Kanagawa styling and optional post-show centering.
---@param chooser hs.chooser
---@param opts? ChooserStyleOptions
---@return hs.chooser
function M.styleChooser(chooser, opts)
    opts = opts or {}
    styledChoosers[chooser] = true

    chooser
        :bgDark(true)
        :fgColor(hexToRgb(M.palette.fujiWhite))
        :subTextColor(hexToRgb(M.palette.katanaGray))
        :rows(opts.rows or 8)
        :searchSubText(opts.searchSubText ~= false)

    if opts.width then chooser:width(opts.width) end
    if opts.title then chooser:placeholderText(opts.title) end

    if opts.vcenter ~= false then
        chooser:showCallback(function()
            hs.timer.doAfter(0.03, function()
                local win = hs.window.focusedWindow()
                if win and win:application():name() == "Hammerspoon" then
                    local screen = win:screen():frame()
                    local f = win:frame()
                    f.x = screen.x + (screen.w - f.w) / 2
                    f.y = screen.y + (screen.h - f.h) / 2
                    win:setFrame(f)
                end
            end)
        end)
    end

    return chooser
end

--- Shows a chooser after dismissing any currently visible chooser.
---@param chooser hs.chooser
function M.showChooser(chooser)
    showRequestId = showRequestId + 1
    local requestId = showRequestId

    if chooser:isVisible() then
        chooser:hide()
        return
    end

    local dismissedChooser = false
    for styledChooser in pairs(styledChoosers) do
        if styledChooser ~= chooser and styledChooser:isVisible() then
            styledChooser:hide()
            dismissedChooser = true
        end
    end

    if not dismissedChooser then
        chooser:show()
        return
    end

    hs.timer.doAfter(0.05, function()
        if requestId == showRequestId then
            chooser:show()
        end
    end)
end

return M
