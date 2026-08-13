local w = require("wombat")
local settings = w.using("settings")

w.module.from(".config")
w.install("zsh", { exclude = { "env/functions.zsh.tmpl" } })
w.install("zsh/env/functions.zsh", {
    with = { github_username = settings.shell.github_username },
})
