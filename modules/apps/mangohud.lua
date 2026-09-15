local w = require("wombat")
local machine = w.module.config().machine or {}
local theme = w.using("theme")

if machine.name ~= "bob" or machine.platform ~= "fedora" then
    error("the MangoHud Steam integration is currently scoped to Bob on Fedora")
end

w.module.from(".")
w.install(".config/MangoHud/MangoHud.conf.tmpl", {
    to = ".config/MangoHud/MangoHud.conf",
    with = { theme = theme, fps_limit = false },
})
w.install(".config/MangoHud/MangoHud.conf.tmpl", {
    to = ".config/MangoHud/wine-OuterWilds.conf",
    with = { theme = theme, fps_limit = 120 },
})
w.install(".local/bin/steam-mangohud")
w.install(".local/share/applications/steam.desktop.tmpl", {
    to = ".local/share/applications/steam.desktop",
    with = { home = w.paths.home },
})
