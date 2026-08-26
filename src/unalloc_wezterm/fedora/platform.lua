-- KDE provides the outer shadow and compositor effects. RESIZE retains a thin
-- useful frame without restoring a title bar or a second tab/window manager.
local wezterm = require("wezterm")

return {
	colors = {
		background = "{{theme.palette.bg2}}",
	},

	default_prog = { "/bin/zsh", "-l" },
	window_padding = {
		left = 10,
		right = 10,
		top = 0,
		bottom = 0,
	},
	wayland_window_background_blur = true,
	window_background_opacity = 0.80,
	window_decorations = "TITLE | RESIZE",

	font_size = 12.0,
}
