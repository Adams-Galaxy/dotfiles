local w = require("wombat")
local machine = w.using("machine")
local theme = w.using("theme")

if machine.platform ~= "fedora" then
    error("the Hyprland desktop is currently defined only for Fedora")
end

-- Keep the source tree together without leaking its organisational directory
-- into ~/.config. The shell will be developed separately and added here one
-- functional module at a time.
w.module.from("@hyprland")
local context = { home = w.paths.home, theme = theme }

w.install(".config/hypr/hyprland.lua.tmpl", { to = ".config/hypr/hyprland.lua", with = context })
w.install(".config/quickshell/wombat/shell.qml", { to = ".config/quickshell/wombat/shell.qml" })
w.install(".config/sunshine/sunshine.conf", { to = ".config/sunshine/sunshine.conf" })
w.install(".config/sunshine/apps.json", { to = ".config/sunshine/apps.json" })
w.install(".config/systemd/user/remote-desktop-sunshine.service", {
    to = ".config/systemd/user/remote-desktop-sunshine.service",
})
w.install(".local/bin/remote-desktop-session", { to = ".local/bin/remote-desktop-session" })

return { shell = "quickshell" }
