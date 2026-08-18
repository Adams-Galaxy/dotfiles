local w = require("wombat")

local machine_settings = w.toml.decode("knobs/settings.toml").machine or {}
local machine_resolver = require("machine.resolve")
local input = w.inputs({
    -- `auto` is the ordinary path: macOS selects Cary, while Fedora and WSL
    -- select Bob. `none` deliberately builds the shared configuration only.
    machine = w.input.choice({
        values = { "auto", "none", "cary", "bob" },
        default = machine_settings.default or "auto",
    }),
})

local machine = machine_resolver.resolve(w, input.machine, machine_settings)

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

if machine.platform == "macos" then
    w.providers({ { name = "brew", with = { aliases = aliases.brew or {} } } })
elseif machine.platform == "wsl" then
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
elseif machine.platform == "fedora" then
    w.providers({
        { name = "dnf", with = { aliases = aliases.dnf or {} } },
        "git",
    })
end

w.use("machine", { resolved = machine })
w.use("settings", { machine = machine })
w.use("theme")

if machine.name == "cary" then
    w.use("cary")
elseif machine.name == "bob" then
    w.use("bob")
    if machine.platform == "fedora" then
        w.use("fedora")
        w.use("kde")
    elseif machine.platform == "wsl" then
        w.use("wsl")
    end
end

-- A machine layer opts into machine bring-up. Shared artifacts still build
-- without it, which keeps an unrecognised host safe and useful.
if machine.enabled then
    w.use("bootstrap", { machine = machine })
end
w.use("shell")
w.use("zsh", { machine = machine })
w.use("git")
w.use("nvim")
w.use("tmux")
w.use("wezterm")
w.use("wezterm_platform", { machine = machine })
w.use("starship")
w.use("fastfetch")
w.use("yazi")
w.use("bat")
w.use("auto")
