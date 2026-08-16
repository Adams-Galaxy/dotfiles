local w = require("wombat")
local settings = w.using("settings")
local resolver = require("theme.resolve")
local contracts = require("theme.contracts")

local name = settings.theme.name
if type(name) ~= "string" or name == "" then
    error("theme settings require a non-empty theme.name")
end

local root = "themes/" .. name .. "/"
local palette = w.toml.decode(root .. "palette.toml").palette
local semantic = w.toml.decode(root .. "semantic.toml")
local theme = resolver.resolve(palette, semantic)

for consumer, paths in pairs(contracts) do
    resolver.require_paths(theme, consumer, paths)
end

w.template.helpers("theme.colors", { prefix = "color_" })

return theme
