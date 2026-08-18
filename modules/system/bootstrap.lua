local w = require("wombat")
local p = w.paths
local machine = w.module.config().machine or {}

local data = w.toml.decode("knobs/packages.toml")
local commands = data.command or {}
local pkgs = data.package or {}

local function os_matches(entry)
    if entry.os == nil then
        return true
    end
    for _, name in ipairs(entry.os) do
        if name == w.os.name then
            return true
        end
    end
    return false
end

local function scope_matches(entry, field, value)
    if entry[field] == nil then
        return true
    end
    for _, name in ipairs(entry[field]) do
        if name == value then
            return true
        end
    end
    return false
end

for name, cmd in pairs(commands) do
    if os_matches(cmd)
        and scope_matches(cmd, "machines", machine.name)
        and scope_matches(cmd, "platforms", machine.platform)
    then
        if cmd.accept then
            w.prefer.command(name, { accept = cmd.accept, when = "deploy.before" })
        else
            w.need.command(name, { when = "deploy.before" })
        end
    end
end

for name, pkg in pairs(pkgs) do
    if os_matches(pkg)
        and scope_matches(pkg, "machines", machine.name)
        and scope_matches(pkg, "platforms", machine.platform)
    then
        w.need.package(name, {
            provider = pkg.provider,
            with = pkg.with,
            publishes = pkg.publishes,
            when = "deploy.before",
        })
    end
end

-- antidote doesn't fit knobs/packages.toml's [package.*] shape - its
-- provider AND `with` differ per platform, and the Linux `with.to`
-- needs p.home, which a static TOML table can't express.
if machine.platform == "macos" then
    -- Confirmed via `brew list antidote`: the formula ships only
    -- share/antidote/antidote.zsh and a functions/ dir, no bin/ at all -
    -- there is no command to check, ever, on this platform.
    w.need.package("antidote", { provider = "brew", when = "deploy.before" })
elseif machine.platform == "wsl" or machine.platform == "fedora" then
    -- Package-manager availability is not uniform across Linux distributions;
    -- retain the existing direct Git checkout rather than coupling shell
    -- plugins to Apt or DNF policy. Pinning the provider keeps its Git-specific
    -- options from being offered to the system package provider.
    w.need.package("antidote", {
        provider = "git",
        when = "deploy.before",
        with = {
            repository = "https://github.com/mattmc3/antidote.git",
            to = p.home .. "/.antidote",
        },
    })
end
