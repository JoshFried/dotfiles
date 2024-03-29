local wezterm = require("wezterm")

return {

	font = wezterm.font_with_fallback({
		{
			family = "Monaco",
			weight = "Bold",
		},
		{
			family = "JetBrainsMono Nerd Font",
			scale = 1.8,
			weight = "Medium",
		},
	}),

	font_size = 15.0,

	color_scheme_dirs = { "~/.config/wezterm/colors" },

	color_scheme = "Kanagawa (Gogh)",

	window_padding = {
		left = 15,
		right = 15,
		top = 10,
		bottom = 0,
	},

	window_background_opacity = 0.94,
	window_decorations = "RESIZE",
	enable_tab_bar = false,
	scrollback_lines = 5000,
	enable_scroll_bar = false,
	check_for_updates = false,

	keys = {
		-- NOTE: this is how we keep good natural macos text editing navigation
		{ key = "LeftArrow", mods = "OPT", action = wezterm.action({ SendString = "\x1bb" }) },
		{ key = "RightArrow", mods = "OPT", action = wezterm.action({ SendString = "\x1bf" }) },
		{ key = "Backspace", mods = "CMD", action = wezterm.action({ SendString = "\x15" }) },
		{ key = "LeftArrow", mods = "CMD", action = wezterm.action({ SendString = "\x1bOH" }) },
		{ key = "RightArrow", mods = "CMD", action = wezterm.action({ SendString = "\x1bOF" }) },
	},
}
