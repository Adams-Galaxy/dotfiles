-- A conventional Linux fallback keeps the shared configuration buildable on
-- distributions that are deliberately not assigned to a machine layer yet.
local wezterm = require("wezterm")

return {
  default_prog = { "/bin/zsh", "-l" },
  mouse_bindings = {
    {
      event = { Drag = { streak = 1, button = "Left" } },
      mods = "CTRL",
      mouse_reporting = true,
      action = wezterm.action.StartWindowDrag,
    },
  },
}
