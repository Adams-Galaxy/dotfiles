local w = require("wombat")
local machine = w.module.config().machine or {}
local platform = machine.platform
local theme = w.using("theme")
local target = require("wezterm.target")

if platform ~= "macos" and platform ~= "fedora" and platform ~= "wsl" and platform ~= "linux" then
    error(("WezTerm has no platform configuration for %q"):format(platform))
end

-- Platform policy is compiled beside the shared entrypoint. On WSL this is
-- Windows-native WezTerm's tree, so both modules use the same external root.
w.module.from("@wezterm/" .. platform)
w.install("platform.lua", {
    to = target.config_dir() .. "/config/platform.lua",
    with = { theme = theme },
})
