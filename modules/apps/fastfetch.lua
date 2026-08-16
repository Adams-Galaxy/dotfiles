local w = require("wombat")
local theme = w.using("theme")

w.module.from(".config")
w.install("fastfetch", { with = { theme = theme } })
