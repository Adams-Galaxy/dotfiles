local w = require("wombat")
local theme = w.using("theme")
local target = require("wezterm.target")

w.module.from(".config")

local config_dir = target.config_dir()
local external = w.wsl

local function destination(path)
    if external then
        return config_dir .. "/" .. path
    end
end

-- Install each leaf explicitly: this keeps template suffix removal and the
-- Windows external endpoint exact, instead of relying on directory traversal
-- to infer a destination for a rendered child.
w.install("wezterm/wezterm.lua", { to = destination("wezterm.lua") })
w.install("wezterm/config/appearance.lua", {
    to = destination("config/appearance.lua"),
    with = { theme = theme },
})
w.install("wezterm/config/general.lua", { to = destination("config/general.lua") })
w.install("wezterm/config/keys.lua", { to = destination("config/keys.lua") })
