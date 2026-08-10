-- Window size, scrollback, bell, and terminal identification — the
-- non-visual half of the iTerm profile import.
local wezterm = require("wezterm")

return {
  prefer_egl = true, -- Default.json: 'GPU Renderer': 'OpenGL (EGL)'.

  -- Keep WezTerm's instant fullscreen rather than creating a dedicated
  -- macOS Space. Leave the menu bar visible: on this notched display it
  -- occupies otherwise unusable space and keeps the menu readily available.
  native_macos_fullscreen_mode = false,
  macos_simple_fullscreen_show_menu_bar = true,

  -- Extending behind the notch has no effect while the menu bar remains
  -- visible, so keep the fullscreen frame below it.
  macos_fullscreen_extend_behind_notch = false,

  -- Default.json: Columns 80, Rows 25.
  initial_cols = 94,
  initial_rows = 27,

  -- Default.json had 'Unlimited Scrollback': false, 'Scrollback Lines':
  -- 1000 — but that's iTerm's own buffer, separate from tmux's, which is
  -- what actually matters day to day (history-limit 100000 in
  -- dot_tmux.conf.tmpl). This is only what's visible outside tmux (or
  -- before it attaches), so a middle-ground value rather than a literal
  -- copy of iTerm's conservative default.
  scrollback_lines = 10000,

  -- 'Silence Bell': false, 'Visual Bell': true, 'Flashing Bell': false —
  -- shown, not heard, not a full-screen flash.
  audible_bell = "Disabled",
  visual_bell = {
    fade_in_duration_ms = 75,
    fade_out_duration_ms = 75,
    target = "CursorColor",
  },

  -- Matches the iTerm profile's explicit 'Terminal Type': xterm-256color
  -- exactly, and — more importantly given how often this machine SSHes
  -- out — keeps every remote host's terminfo working with zero setup.
  -- WezTerm's own "wezterm" terminfo entry is a superset (undercurl,
  -- etc.) but has to be installed on whatever's on the other end of each
  -- ssh session, which isn't worth it for the extra capabilities.
  term = "xterm-256color",

  -- Already the default shell; explicit for parity across whatever this
  -- config later runs on (mirrors dot_config/zsh/os/macos.zsh being
  -- macOS-specific — this file's the same idea for WezTerm, staying
  -- correct even if it starts getting used cross-platform).
  default_prog = { "/bin/zsh", "-l" },

  -- Cmd+drag-to-move over a mouse-reporting pane (tmux/nvim) needs a real
  -- mouse_bindings entry, not a bypass_mouse_reporting_modifiers tweak —
  -- checked directly against WezTerm's own source
  -- (wezterm-gui/src/termwindow/mouseevent.rs): that option doesn't add
  -- an alternative trigger, it *strips those exact modifier bits from the
  -- held modifiers* before binding lookup, and the default SUPER+Drag ->
  -- StartWindowDrag binding (inputmap.rs) only matches when
  -- mouse_reporting is already false. So the by-design way to reach it
  -- while reporting is on is holding the bypass modifier (Shift, default)
  -- *and* Cmd at once — Shift strips itself to flip reporting off, Cmd
  -- survives that strip and matches the binding's own mods. Cmd alone
  -- can't do both jobs simultaneously: using SUPER as the bypass modifier
  -- would strip SUPER before lookup, leaving nothing left to match
  -- SUPER's own binding.
  mouse_bindings = {
    {
      event = { Drag = { streak = 1, button = "Left" } },
      mods = "CMD",
      mouse_reporting = true,
      action = wezterm.action.StartWindowDrag,
    },
  },
}
