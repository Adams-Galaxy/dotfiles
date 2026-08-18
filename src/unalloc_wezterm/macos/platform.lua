-- macOS keeps the deliberately minimal iTerm-inspired frame: no title bar,
-- but resize affordances and a native shadow around the translucent window.
local wezterm = require("wezterm")

local keys = {}

-- Cmd+drag must be explicit while tmux or Neovim is reporting mouse input;
-- the default drag binding only applies after mouse reporting is already off.
local mouse_bindings = {
  {
    event = { Drag = { streak = 1, button = "Left" } },
    mods = "CMD",
    mouse_reporting = true,
    action = wezterm.action.StartWindowDrag,
  },
}

-- Toggle a real macOS Space for comparison with WezTerm's instant fullscreen.
wezterm.on("toggle-native-fullscreen", function(window, _pane)
  local overrides = window:get_config_overrides() or {}
  local current = overrides.native_macos_fullscreen_mode
  if current == nil then
    current = false
  end
  overrides.native_macos_fullscreen_mode = not current
  window:set_config_overrides(overrides)
  window:toast_notification(
    "WezTerm",
    "native_macos_fullscreen_mode -> " .. tostring(overrides.native_macos_fullscreen_mode),
    nil,
    2000
  )
end)

table.insert(keys, {
  key = "f",
  mods = "CTRL|ALT",
  action = wezterm.action.EmitEvent("toggle-native-fullscreen"),
})

return {
  prefer_egl = true,
  native_macos_fullscreen_mode = false,
  macos_simple_fullscreen_show_menu_bar = true,
  macos_fullscreen_extend_behind_notch = false,
  default_prog = { "/bin/zsh", "-l" },
  window_padding = {
    left = 30,
    right = 20,
    top = 28,
    bottom = 0,
  },
  macos_window_background_blur = 40,
  window_background_opacity = 0.66,
  window_decorations = "RESIZE | MACOS_FORCE_ENABLE_SHADOW",
  mouse_bindings = mouse_bindings,
  keys = keys,
}
