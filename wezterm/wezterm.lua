local wezterm = require("wezterm")

return {

	font = wezterm.font_with_fallback({
		{
			family = "RecMonoLinear Nerd Font Mono",
			weight = "Bold",
			harfbuzz_features = { "liga = 1" },
		},
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

	window_background_opacity = 0.90,
	macos_window_background_blur = 20,
	window_decorations = "RESIZE",
	window_close_confirmation = "NeverPrompt",
	native_macos_fullscreen_mode = true,
	adjust_window_size_when_changing_font_size = false,
	front_end = "WebGpu",
	max_fps = 120,
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
