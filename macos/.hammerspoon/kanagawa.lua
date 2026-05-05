-- Kanagawa Wave theme helpers for Hammerspoon.
-- Shared palette + a styleChooser() helper applied uniformly to the audio,
-- wifi, and bluetooth pickers.
--
-- hs.chooser doesn't expose a font API, so glyphs stay in the system font.
-- We style colors, width, row count, dark chrome, and enable subtext search.

local M = {}

-- ── Palette (matches dotfiles README.md) ──────────────────────
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

-- Convert a "#RRGGBB" string into the { red, green, blue, alpha } table
-- that hs color APIs expect.
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

-- ── styleChooser(chooser) ─────────────────────────────────────
-- Apply Kanagawa chrome to an hs.chooser. Safe to call multiple times.
-- Pass opts = { rows = 10, searchSubText = true, vcenter = false } to override.
--
-- hs.chooser has no y-position API, so vertical centering is done by
-- monkey-patching :show() to reposition the chooser's window after it
-- appears. 30ms delay is small enough to be visually unnoticeable on
-- the devices I've tested but large enough for the panel to exist.
function M.styleChooser(chooser, opts)
    opts = opts or {}

    chooser
        :bgDark(true)
        :fgColor(hexToRgb(M.palette.fujiWhite))
        :subTextColor(hexToRgb(M.palette.katanaGray))
        :rows(opts.rows or 8)
        :searchSubText(opts.searchSubText ~= false)

    if opts.width then chooser:width(opts.width) end

    if opts.vcenter ~= false then
        chooser:showCallback(function()
            hs.timer.doAfter(0.03, function()
                local win = hs.window.focusedWindow()
                if win and win:application():name() == "Hammerspoon" then
                    local screen = hs.screen.mainScreen():frame()
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

return M
