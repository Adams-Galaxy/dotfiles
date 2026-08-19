local w = require("wombat")
local theme = w.using("theme")
local machine = w.module.config().machine or {}

w.module.from(".config")

local options = { with = { theme = theme } }
if machine.platform == "macos" then
    -- Lazygit follows XDG on Linux, but macOS keeps its native configuration
    -- under Library/Application Support rather than ~/.config.
    options.to = "Library/Application Support/lazygit/config.yml"
    w.install("lazygit/config.yml", options)
else
    w.install("lazygit", options)
end
