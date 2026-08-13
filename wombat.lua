local w = require("wombat")

local input = w.inputs({
    profile = w.input.choice({ values = { "personal", "work" }, default = "personal" }),
})

-- Provider package-name aliases are root-only config, folded once here
-- from every package row's `alias` table (see data/packages.toml) -
-- modules/bootstrap.lua only declares needs, it never touches providers.
local packages = w.data.toml("data/packages.toml").package

local function merged_aliases()
    local aliases = {}
    for _, pkg in ipairs(packages) do
        for provider, names in pairs(pkg.alias or {}) do
            aliases[provider] = aliases[provider] or {}
            for command, package_name in pairs(names) do
                aliases[provider][command] = package_name
            end
        end
    end
    return aliases
end

local aliases = merged_aliases()

if w.target.os.name == "macos" then
    w.providers({ { name = "brew", with = { aliases = aliases.brew or {} } } })
else
    w.providers({ { name = "apt", with = { update = true, aliases = aliases.apt or {} } } })
end

w.use("settings", { profile = input.profile })
w.use("bootstrap", { profile = input.profile })
w.use("shell")
w.use("zsh", { profile = input.profile })
w.use("git")
w.use("nvim")
w.use("tmux")
w.use("wezterm")
w.use("starship")
w.use("fastfetch")
w.use("yazi")
w.use("bat")
w.use("auto")
