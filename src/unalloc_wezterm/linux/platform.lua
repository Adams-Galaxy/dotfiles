-- A conventional Linux fallback keeps the shared configuration buildable on
-- distributions that are deliberately not assigned to a machine layer yet.
local wezterm = require("wezterm")

return {
  default_prog = { "/bin/zsh", "-l" },
  font_size = 12.0,
}
