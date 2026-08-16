local w = require("wombat")
local p = w.paths
local profile = w.module.config().profile

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

local function profile_matches(entry)
    if entry.profiles == nil then
        return true
    end
    for _, name in ipairs(entry.profiles) do
        if name == profile then
            return true
        end
    end
    return false
end

for name, cmd in pairs(commands) do
    if os_matches(cmd) and profile_matches(cmd) then
        if cmd.accept then
            w.prefer.command(name, { accept = cmd.accept, when = "deploy.before" })
        else
            w.need.command(name, { when = "deploy.before" })
        end
    end
end

for name, pkg in pairs(pkgs) do
    if os_matches(pkg) and profile_matches(pkg) then
        w.need.package(name, {
            provider = pkg.provider,
            with = pkg.with,
            when = "deploy.before",
        })
    end
end

-- antidote doesn't fit knobs/packages.toml's [package.*] shape - its
-- provider AND `with` differ per platform, and the Linux `with.to`
-- needs p.home, which a static TOML table can't express.
if w.macos then
    -- Confirmed via `brew list antidote`: the formula ships only
    -- share/antidote/antidote.zsh and a functions/ dir, no bin/ at all -
    -- there is no command to check, ever, on this platform.
    w.need.package("antidote", { provider = "brew", when = "deploy.before" })
else
    -- Debian repos don't package antidote at all - it was git-cloned
    -- directly pre-migration too. Provider is pinned explicitly: apt is
    -- also registered on Linux (see wombat.lua), and an unpinned package
    -- candidate with git-specific `with` options would hard-error there
    -- rather than gracefully skip.
    w.need.package("antidote", {
        provider = "git",
        when = "deploy.before",
        with = {
            repository = "https://github.com/mattmc3/antidote.git",
            to = p.home .. "/.antidote",
        },
    })
end
