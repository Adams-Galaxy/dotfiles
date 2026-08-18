local w = require("wombat")
local machine = w.module.config().machine or {}
local platform = machine.platform

if platform ~= "macos" and platform ~= "fedora" and platform ~= "wsl" and platform ~= "linux" then
    error(("WezTerm has no platform configuration for %q"):format(platform))
end

-- Platform policy is compiled into the normal WezTerm tree. The live config
-- never has to rediscover whether it runs under macOS, KDE, or Windows.
w.module.from("@wezterm/" .. platform, { to = ".config/wezterm/config" })
w.install("platform.lua")
