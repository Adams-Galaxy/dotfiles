local M = {}

function M.resolve(w, requested, settings)
    local platform
    if w.macos then
        platform = "macos"
    elseif w.wsl then
        platform = "wsl"
    elseif w.linux and w.os.distribution and w.os.distribution.id == "fedora" then
        platform = "fedora"
    elseif w.linux then
        platform = "linux"
    else
        platform = "unknown"
    end

    local name = requested
    if name == "auto" then
        if settings.auto_detect == false then
            name = "none"
        elseif platform == "macos" then
            name = "cary"
        elseif platform == "wsl" or platform == "fedora" then
            name = "bob"
        else
            name = "none"
        end
    end

    return {
        name = name,
        platform = platform,
        enabled = name ~= "none",
    }
end

return M
