-- Colors, font, and window chrome — pulled from the exported iTerm2
-- profile/colors in ~/Downloads (iterm-colors.itermcolors, Default.json)
-- for as close to a 1:1 visual match as WezTerm's model allows. The
-- "(Dark)" keys in the .itermcolors file are what's actually in use
-- (light/dark are both defined, but the whole rest of this setup —
-- tmux's border colour, fzf's palette, bat's theme — is gruvbox-dark
-- throughout); the plain, unsuffixed keys in that file are a slightly
-- different blended variant and not what's on screen day to day.
local wezterm = require("wezterm")

local colors = {
  foreground = "#ebdbb2",
  background = "#1d2021",
  cursor_bg = "#ebdbb2",
  cursor_fg = "#1d2021",
  cursor_border = "#ebdbb2",
  selection_fg = "#1d2021",
  selection_bg = "#ebdbb2",
  ansi = {
    "#1d2021", -- black
    "#cc241d", -- red
    "#98971a", -- green
    "#d79921", -- yellow
    "#458588", -- blue
    "#b16286", -- purple
    "#689d6a", -- aqua
    "#a89984", -- white
  },
  brights = {
    "#928374", -- bright black
    "#fb4934", -- bright red
    "#b8bb26", -- bright green
    "#fabd2f", -- bright yellow
    "#83a598", -- bright blue
    "#d3869b", -- bright purple
    "#8ec07c", -- bright aqua
    "#ebdbb2", -- bright white
  },
}

return {
  colors = colors,

  -- Default.json: 'Normal Font': 'JetBrainsMonoNF-Regular 16'. WezTerm
  -- shapes bold/italic from the family automatically, no separate
  -- bold/italic font entries needed the way iTerm's "Use Bold/Italic
  -- Font" checkboxes implied.
  font = wezterm.font("JetBrainsMono Nerd Font"),
  font_size = 16.0,

  -- 'Cursor Type': 0 (box) + 'Blinking Cursor': true.
  default_cursor_style = "BlinkingBlock",

  -- Transparency (iTerm 'Transparency': 0.305, inverted scale, hence 1
  -- minus, then hand-tuned from there) + blur. Confirmed via WezTerm's own
  -- docs that opacity < 1.0 disables the native window shadow outright,
  -- and forces WezTerm to custom-composite the window instead of
  -- deferring to macOS's normal opaque-window drawing — the shadow/corner
  -- rendering bugs traced back to this. The stable build in use here
  -- (20240203) is over two years old with no newer stable release since;
  -- nightly has diverged significantly on exactly this part of macOS
  -- windowing (MACOS_FORCE_SQUARE_CORNERS, titlebar-colour-matching, a
  -- notch-handling option, none of which exist in this build) — worth
  -- trying if the instability persists at this opacity, since it's
  -- squarely the area that's seen active fixes since this build shipped.
  window_background_opacity = 0.66,
  macos_window_background_blur = 24,

  -- More breathing room than iTerm's own 'Horizontal/Vertical Spacing: 1'
  -- (its minimum) — a deliberate departure from strict parity, by request.
  -- top = 0 specifically: with the tab bar off and no TITLE decoration,
  -- WezTerm's own docs say window dragging falls to the tab bar (off) or
  -- SUPER+drag (already a default binding) instead — so the reserved
  -- strip at the top wasn't buying anything, just pushing content down.
  window_padding = {
    left = 30,
    right = 20,
    top = 28,
    bottom = 0,
  },

  -- tmux's own status bar already shows session/window info, so a second
  -- WezTerm tab bar on top of it is redundant chrome rather than a
  -- feature — same reasoning as not giving WezTerm its own leader key.
  -- With it off, window dragging is SUPER (Cmd) + drag anywhere in the
  -- window instead — a default WezTerm binding, not something configured
  -- here.
  enable_tab_bar = false,

  window_decorations = "RESIZE | MACOS_FORCE_ENABLE_SHADOW",
}
