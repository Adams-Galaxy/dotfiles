local w = require("wombat")
local config = w.module.config()
local profile = config.profile

local raw = w.data.toml("knobs/settings.toml")
local overrides = (raw.profiles and raw.profiles[profile]) or {}

local function merge(base, over)
    local result = {}
    for k, v in pairs(base or {}) do
        result[k] = v
    end
    for k, v in pairs(over or {}) do
        result[k] = v
    end
    return result
end

return {
    git = merge(raw.git, overrides.git),
    shell = merge(raw.shell, overrides.shell),
}
