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

if w.target.os.name == "linux" then
    w.need.package("antidote", {
        provider = "git",
        when = "deploy.before",
        with = {
            repository = "https://github.com/mattmc3/antidote.git",
            to = w.host.home .. "/.antidote",
        },
    })
end
