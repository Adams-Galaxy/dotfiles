-- Theme resolution is strict because a plausible fallback colour hides a
-- broken theme until it reaches a terminal or editor far from its source.
local colors = require("theme.colors")

local M = {}

local descriptor_keys = {
    ref = true,
    mix = true,
    weight = true,
    alpha = true,
    lighten = true,
    darken = true,
}

local function fail(message)
    error("theme resolution: " .. message, 3)
end

local function path_value(root, path)
    if type(path) ~= "string" or path == "" then
        fail("reference path must be a non-empty string")
    end
    local value = root
    for segment in path:gmatch("[^.]+") do
        if type(value) ~= "table" or value[segment] == nil then
            fail(("unknown reference %q"):format(path))
        end
        value = value[segment]
    end
    return value
end

local function cached_path_value(root, path)
    local value = root
    for segment in path:gmatch("[^.]+") do
        if type(value) ~= "table" then
            return nil
        end
        value = value[segment]
        if value == nil then
            return nil
        end
    end
    return value
end

local function set_path(root, path, value)
    local parent = root
    local parts = {}
    for segment in path:gmatch("[^.]+") do
        parts[#parts + 1] = segment
    end
    for index = 1, #parts - 1 do
        local segment = parts[index]
        parent[segment] = parent[segment] or {}
        parent = parent[segment]
    end
    parent[parts[#parts]] = value
end

local function is_descriptor(value)
    if type(value) ~= "table" then
        return false
    end
    for key in pairs(value) do
        if descriptor_keys[key] then
            return true
        end
    end
    return false
end

local function validate_descriptor(value, path)
    for key in pairs(value) do
        if not descriptor_keys[key] then
            fail(("%s has unsupported transform key %q"):format(path, key))
        end
    end
    if (value.ref == nil) == (value.mix == nil) then
        fail(("%s must contain exactly one of ref or mix"):format(path))
    end
    if value.mix ~= nil then
        if type(value.mix) ~= "table" or #value.mix ~= 2 then
            fail(("%s mix must name exactly two references"):format(path))
        end
        if type(value.weight) ~= "number" then
            fail(("%s mix requires a numeric weight"):format(path))
        end
    elseif value.weight ~= nil then
        fail(("%s weight is only valid with mix"):format(path))
    end
    if value.lighten ~= nil and value.darken ~= nil then
        fail(("%s cannot lighten and darken in one transform"):format(path))
    end
end

function M.resolve(palette, semantic)
    local raw = { palette = palette }
    for key, value in pairs(semantic) do
        raw[key] = value
    end

    local resolved = {}
    local resolving = {}

    local function resolve_path(path)
        local cached = cached_path_value(resolved, path)
        if cached ~= nil then
            return cached
        end
        if resolving[path] then
            local cycle = {}
            for index, entry in ipairs(resolving) do
                if entry == path or #cycle > 0 then
                    cycle[#cycle + 1] = entry
                end
            end
            cycle[#cycle + 1] = path
            fail("reference cycle " .. table.concat(cycle, " -> "))
        end

        local value = path_value(raw, path)
        if type(value) == "table" and not is_descriptor(value) then
            fail(("%s names a namespace, not a colour"):format(path))
        end

        resolving[#resolving + 1] = path
        resolving[path] = true

        local result
        if type(value) == "string" then
            if path:match("^palette%.") then
                if not value:match("^#%x%x%x%x%x%x$") and value ~= "#00000000" then
                    fail(("palette value %s must be #RRGGBB or transparent"):format(path))
                end
                result = value:lower()
            else
                result = resolve_path(value)
            end
        elseif is_descriptor(value) then
            validate_descriptor(value, path)
            if value.ref ~= nil then
                result = resolve_path(value.ref)
            else
                result = colors.mix(resolve_path(value.mix[1]), resolve_path(value.mix[2]), value.weight)
            end
            if value.lighten ~= nil then
                result = colors.lighten(result, value.lighten)
            elseif value.darken ~= nil then
                result = colors.darken(result, value.darken)
            end
            if value.alpha ~= nil then
                result = colors.alpha(result, value.alpha)
            end
        else
            fail(("%s must be a reference or transform"):format(path))
        end

        resolving[path] = nil
        table.remove(resolving)
        set_path(resolved, path, result)
        return result
    end

    local function visit(value, prefix)
        if type(value) ~= "table" or is_descriptor(value) then
            resolve_path(prefix)
            return
        end
        for key, child in pairs(value) do
            local path = prefix == "" and key or prefix .. "." .. key
            visit(child, path)
        end
    end

    visit(raw, "")
    return resolved
end

function M.require_paths(theme, consumer, paths)
    for _, path in ipairs(paths) do
        local ok, value = pcall(path_value, theme, path)
        if not ok or type(value) ~= "string" then
            fail(("%s requires colour role %q"):format(consumer, path))
        end
    end
end

return M
