-- WezTerm config entry point. Split the same way nvim's lua/config/*.lua
-- is: this file just assembles what config/*.lua each return, so any of
-- them can be dropped in isolation to test it.
--
-- tmux (dot_tmux.conf.tmpl) owns multiplexing here — panes, windows,
-- sessions, Ctrl-hjkl/Cmd-hjkl navigation and resize all already work
-- there and in nvim, so this config deliberately stays out of that
-- business (no leader key, tab bar left off) rather than layering a
-- second, competing multiplexer on top. What's left for WezTerm to own is
-- everything tmux can't reach: font rendering, window chrome, GPU
-- rendering backend — the same split as running nvim inside iTerm2, just
-- with a different outer terminal.

local wezterm = require("wezterm")
local config = wezterm.config_builder and wezterm.config_builder() or {}

local function extend(other)
  for k, v in pairs(other) do
    config[k] = v
  end
end

extend(require("config.appearance"))
extend(require("config.general"))

-- platform.lua is selected during Wombat construction, so a config copied to
-- another machine cannot silently keep the old machine's window policy.
local platform = require("config.platform")
extend(platform)

local keys = require("config.keys")
for _, binding in ipairs(platform.keys or {}) do
  table.insert(keys.keys, binding)
end
extend(keys)

return config
