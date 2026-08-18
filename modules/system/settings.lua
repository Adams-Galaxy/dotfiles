local w = require("wombat")
local config = w.module.config()
local machine = config.machine or {}

local raw = w.toml.decode("knobs/settings.toml")
local machine_overrides = (raw.machines and raw.machines[machine.name]) or {}
local platform_overrides = (raw.platforms and raw.platforms[machine.platform]) or {}

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
    git = merge(merge(raw.git, machine_overrides.git), platform_overrides.git),
    shell = merge(merge(raw.shell, machine_overrides.shell), platform_overrides.shell),
    theme = merge(merge(raw.theme, machine_overrides.theme), platform_overrides.theme),
    machine = machine,
}
