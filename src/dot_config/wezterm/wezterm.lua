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

-- Merge a later layer into an earlier one.  This lets a platform override one
-- member of a structured setting without having to duplicate its siblings:
--
--   colors = { cursor_bg = "#ff0000" }
--
-- replaces only colors.cursor_bg.  Scalars always replace earlier values;
-- tables merge recursively.  Use __wombat_replace to replace a whole table
-- (including a list) instead of overlaying it:
--
--   window_padding = { __wombat_replace = true, left = 0, right = 0 }
local function overlay(target, patch)
  for key, value in pairs(patch) do
    local current = target[key]
    if type(current) == "table" and type(value) == "table" and not value.__wombat_replace then
      overlay(current, value)
    elseif type(value) == "table" and value.__wombat_replace then
      local replacement = {}
      for replacement_key, replacement_value in pairs(value) do
        if replacement_key ~= "__wombat_replace" then
          replacement[replacement_key] = replacement_value
        end
      end
      target[key] = replacement
    else
      target[key] = value
    end
  end
end

overlay(config, require("config.appearance"))
overlay(config, require("config.general"))

-- platform.lua is selected during Wombat construction, so a config copied to
-- another machine cannot silently keep the old machine's window policy.
local platform = require("config.platform")
overlay(config, platform)

local keys = require("config.keys")
for _, binding in ipairs(platform.keys or {}) do
  table.insert(keys.keys, binding)
end
-- Keybindings are an ordered list, not an overlayable map: recursive merging
-- would combine actions at matching indices and make WezTerm reject the config.
config.keys = keys.keys

return config
