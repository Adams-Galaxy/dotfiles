-- This file is consumed by Windows-native WezTerm. Its normal first pane is
-- therefore wsl.exe, while deployment remains in WSL's usual config location.
local wezterm = require("wezterm")

return {
  default_prog = { "wsl.exe", "--cd", "~" },
  mouse_bindings = {
    {
      event = { Drag = { streak = 1, button = "Left" } },
      mods = "CTRL",
      mouse_reporting = true,
      action = wezterm.action.StartWindowDrag,
    },
  },
}
