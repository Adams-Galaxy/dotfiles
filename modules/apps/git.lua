local w = require("wombat")
local settings = w.using("settings")

w.module.from(".config")
w.install("git/ignore")
w.install("git/config", {
    with = {
        full_name = settings.git.full_name,
        email = settings.git.email,
    },
})
