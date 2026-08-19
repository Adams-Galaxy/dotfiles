-- Keep the shared tree and its platform fragment rooted together. On WSL the
-- consumer is Windows-native WezTerm, so its configuration belongs in the
-- resolved Windows profile rather than the Linux distribution's XDG tree.
local w = require("wombat")

local M = {}

function M.config_dir()
    if w.wsl then
        return w.paths.windows.home .. "/.config/wezterm"
    end

    return ".config/wezterm"
end

return M
