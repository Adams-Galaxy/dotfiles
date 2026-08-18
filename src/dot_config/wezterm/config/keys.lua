-- WezTerm's default keytable claims plain Ctrl-h/k/l for its own
-- built-ins (Ctrl-h -> HideApplication, Ctrl-k -> ClearScrollback,
-- Ctrl-l -> ShowDebugOverlay — checked directly via `wezterm show-keys`,
-- not assumed) despite none of that being documented as a conflict risk
-- up front. Every one of those four keys is already load-bearing here:
-- Ctrl-hjkl is vim-tmux-navigator's pane/split navigation (dot_tmux.conf
-- and nvim's keymaps.lua) and Ctrl-l specifically is also fzf-tab's
-- continuous-trigger (dot_config/zsh/completion/fzf-tab.zsh) — so unlike Cmd-h,
-- this isn't one accidental macOS system shortcut, it's most of WezTerm's
-- own default table standing in the way. Cmd-h has the same
-- HideApplication problem for the resize binds (nvim keymaps.lua).
--
-- Nothing here needs disabling *by name* — plain SendKey passthrough
-- bindings for exactly these two-modifiers-times-four-keys combinations
-- override the specific defaults above them without touching anything
-- else WezTerm still owns (tab/font/split management, its own Cmd+letter
-- shortcuts, etc).
local wezterm = require("wezterm")
local act = wezterm.action

local keys = {}
local function passthrough(key, mods)
  table.insert(keys, {
    key = key,
    mods = mods,
    action = act.SendKey({ key = key, mods = mods }),
  })
end

for _, mods in ipairs({ "CTRL", "CMD" }) do
  for _, key in ipairs({ "h", "j", "k", "l" }) do
    passthrough(key, mods)
  end
end

-- Same problem, different keys: WezTerm's own pane-splitting defaults
-- (unused here — tmux owns panes) claim tmux's other always-on binds too.
-- Ctrl+Shift+arrows is tmux's select-pane; WezTerm's ActivatePaneDirection
-- would otherwise eat the keystroke for its own (unused) panes before
-- tmux ever saw it. Alt+Left/Right is tmux's resize-pane, colliding with
-- WezTerm's copy-mode word-move — Alt+Up/Down has no such default and
-- needs nothing extra.
for _, key in ipairs({ "LeftArrow", "RightArrow", "UpArrow", "DownArrow" }) do
  passthrough(key, "SHIFT|CTRL")
end
passthrough("LeftArrow", "ALT")
passthrough("RightArrow", "ALT")

return {
  keys = keys,
}
