local w = require("wombat")
local profile = w.module.config().profile

local packages = w.data.toml("knobs/packages.toml").packages

local function os_matches(pkg)
    if pkg.os == nil then
        return true
    end
    for _, name in ipairs(pkg.os) do
        if name == w.target.os.name then
            return true
        end
    end
    return false
end

local function profile_matches(pkg)
    if pkg.profiles == nil then
        return true
    end
    for _, name in ipairs(pkg.profiles) do
        if name == profile then
            return true
        end
    end
    return false
end

for name, pkg in pairs(packages) do
    if os_matches(pkg) and profile_matches(pkg) then
        if pkg.accept then
            w.prefer.command(name, { accept = pkg.accept, when = "deploy.before" })
        else
            w.need.command(name, { when = "deploy.before" })
        end
    end
end

-- antidote doesn't fit the command loop above on either platform - not a
-- knobs/packages.toml row at all, handled explicitly per target instead.
if w.target.os.name == "macos" then
    -- Confirmed via `brew list antidote`: the formula ships only
    -- share/antidote/antidote.zsh and a functions/ dir, no bin/ at all -
    -- there is no command to check, ever, on this platform. w.need.command
    -- reported it "missing" against a real, correctly-installed package.
    w.need.package("antidote", { provider = "brew", when = "deploy.before" })
else
    -- Debian repos don't package antidote at all - it was git-cloned
    -- directly pre-migration too (see the old scripts/bootstrap.sh's
    -- install_antidote). Wombat's built-in git provider gives this real
    -- check/bootstrap status. provider is pinned explicitly: apt is also
    -- registered on Linux (see wombat.lua), and an unpinned package
    -- candidate with git-specific `with` options would hard-error there
    -- rather than gracefully skip.
    w.need.package("antidote", {
        provider = "git",
        when = "deploy.before",
        with = {
            repository = "https://github.com/mattmc3/antidote.git",
            to = w.host.home .. "/.antidote",
        },
    })
end
