-- Shared terminal behaviour. Platform-specific window chrome, rendering, and
-- launcher commands live in the Wombat-selected config/platform.lua.

return {
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

}
