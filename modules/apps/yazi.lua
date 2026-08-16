local w = require("wombat")
local theme = w.using("theme")

w.module.from(".config")
w.install("yazi", { with = { theme = theme } })
