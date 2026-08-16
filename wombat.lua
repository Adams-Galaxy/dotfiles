local w = require("wombat")

local input = w.inputs({
    profile = w.input.choice({ values = { "personal", "work" }, default = "personal" }),
})

-- Provider package-name aliases are root-only config, folded once here
-- from every [command.*] entry's `alias` table (see knobs/packages.toml) -
-- modules/bootstrap.lua only declares needs, it never touches providers.
-- [package.*] entries name their provider package directly and need no
-- alias translation.
local commands = w.toml.decode("knobs/packages.toml").command or {}

local function merged_aliases()
    local aliases = {}
    for name, cmd in pairs(commands) do
        for provider, package_name in pairs(cmd.alias or {}) do
            aliases[provider] = aliases[provider] or {}
            aliases[provider][name] = package_name
        end
    end
    return aliases
end

local aliases = merged_aliases()

if w.macos then
    w.providers({ { name = "brew", with = { aliases = aliases.brew or {} } } })
else
    -- git is only needed for the antidote package.lua fallback below - not
    -- registered on macOS, where nothing currently needs it (an unpinned
    -- package candidate git can't resolve, e.g. one with no `with.repository`
    -- at all, hard-errors rather than gracefully skipping).
    w.providers({
        {
            name = "apt",
            with = {
                update = true,
                aliases = aliases.apt or {},
                sources = {
                    yazi = {
                        uri = "https://yazi-rs.github.io/builds/",
                        suite = "stable",
                        components = { "main" },
                        architectures = { "amd64", "arm64" },
                        key = {
                            url = "https://yazi-rs.github.io/builds/yazi-keyring.gpg",
                            format = "gpg",
                        },
                    },
                },
            },
        },
        "git",
    })
end

w.use("settings", { profile = input.profile })
w.use("theme")
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
