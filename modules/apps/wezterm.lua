local w = require("wombat")
local theme = w.using("theme")

w.module.from(".config")
w.install("wezterm", {
    exclude = "config/platform.lua",
    with = { theme = theme },
})
