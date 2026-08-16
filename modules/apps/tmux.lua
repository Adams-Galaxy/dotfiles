local w = require("wombat")
local theme = w.using("theme")

w.module.from(".")
w.install(".tmux.conf", { with = { theme = theme } })
w.install(".config/tmux/dotfiles-theme.tmux", { with = { theme = theme } })
