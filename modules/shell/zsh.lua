local w = require("wombat")
local settings = w.using("settings")
local theme = w.using("theme")

local function clipboard_backend()
    local selected = {
        macos = false,
        wayland = false,
        wsl = false,
        x11 = false,
    }

    if w.macos then
        selected.macos = true
        return selected
    end

    if w.wsl then
        selected.wsl = true
        return selected
    end

    local backend = settings.shell.linux_clipboard_backend
    if backend == "wayland" then
        w.need.package("wl-clipboard", { provider = "apt", when = "deploy.before" })
        selected.wayland = true
        return selected
    end
    if backend == "x11" then
        w.need.package("xclip", { provider = "apt", when = "deploy.before" })
        selected.x11 = true
        return selected
    end

    error(
        ("shell.linux_clipboard_backend must be %q or %q, got %q"):format(
            "wayland",
            "x11",
            tostring(backend)
        )
    )
end

w.module.from(".config")
w.install("zsh", {
    with = w.template.context({
        clipboard = clipboard_backend(),
        features = {
            mufetch = w.macos,
        },
        os = w.os,
        paths = w.paths,
        theme = theme,
    }),
})
