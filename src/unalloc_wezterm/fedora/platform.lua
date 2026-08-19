-- KDE provides the outer shadow and compositor effects. RESIZE retains a thin
-- useful frame without restoring a title bar or a second tab/window manager.
local wezterm = require("wezterm")

return {
  default_prog = { "/bin/zsh", "-l" },
  window_padding = {
    left = 30,
    right = 20,
    top = 28,
    bottom = 0,
  },
  wayland_window_background_blur = true,
  window_background_opacity = 0.80,
  window_decorations = "RESIZE",
  mouse_bindings = {
    {
      event = { Drag = { streak = 1, button = "Left" } },
      mods = "CTRL",
      mouse_reporting = true,
      action = wezterm.action.StartWindowDrag,
    },
  },
}
