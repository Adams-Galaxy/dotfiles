-- Pure colour operations shared by configuration-time renderers and the
-- deterministic Handlebars helper runtime. Keeping this module dependency-free
-- prevents helper output from depending on host state.
local M = {}

local function fail(message)
    error("theme colour: " .. message, 3)
end

local function amount(value, name)
    if type(value) ~= "number" or value ~= value or value < 0 or value > 1 then
        fail(("%s must be a finite number from 0 through 1"):format(name))
    end
    return value
end

local function round(value)
    return math.floor(value + 0.5)
end

local function parse(hex)
    if type(hex) ~= "string" then
        fail("colour must be a #RRGGBB string")
    end
    local red, green, blue = hex:match("^#(%x%x)(%x%x)(%x%x)$")
    if red == nil then
        fail(("expected #RRGGBB, got %q"):format(hex))
    end
    return tonumber(red, 16), tonumber(green, 16), tonumber(blue, 16)
end

local function encode(red, green, blue)
    return ("#%02x%02x%02x"):format(round(red), round(green), round(blue))
end

function M.normalize(hex)
    local red, green, blue = parse(hex)
    return encode(red, green, blue)
end

function M.alpha(hex, opacity)
    local red, green, blue = parse(hex)
    return ("#%02x%02x%02x%02x"):format(red, green, blue, round(amount(opacity, "opacity") * 255))
end

function M.mix(first, second, weight)
    local first_red, first_green, first_blue = parse(first)
    local second_red, second_green, second_blue = parse(second)
    local factor = amount(weight, "weight")
    return encode(
        first_red + (second_red - first_red) * factor,
        first_green + (second_green - first_green) * factor,
        first_blue + (second_blue - first_blue) * factor
    )
end

local function rgb_to_hsl(red, green, blue)
    red, green, blue = red / 255, green / 255, blue / 255
    local maximum = math.max(red, green, blue)
    local minimum = math.min(red, green, blue)
    local lightness = (maximum + minimum) / 2
    if maximum == minimum then
        return 0, 0, lightness
    end

    local delta = maximum - minimum
    local saturation = lightness > 0.5 and delta / (2 - maximum - minimum) or delta / (maximum + minimum)
    local hue
    if maximum == red then
        hue = (green - blue) / delta + (green < blue and 6 or 0)
    elseif maximum == green then
        hue = (blue - red) / delta + 2
    else
        hue = (red - green) / delta + 4
    end
    return hue / 6, saturation, lightness
end

local function hue_to_rgb(first, second, hue)
    if hue < 0 then
        hue = hue + 1
    elseif hue > 1 then
        hue = hue - 1
    end
    if hue < 1 / 6 then
        return first + (second - first) * 6 * hue
    end
    if hue < 1 / 2 then
        return second
    end
    if hue < 2 / 3 then
        return first + (second - first) * (2 / 3 - hue) * 6
    end
    return first
end

local function hsl_to_rgb(hue, saturation, lightness)
    if saturation == 0 then
        local channel = lightness * 255
        return channel, channel, channel
    end
    local second = lightness < 0.5
            and lightness * (1 + saturation)
        or lightness + saturation - lightness * saturation
    local first = 2 * lightness - second
    return hue_to_rgb(first, second, hue + 1 / 3) * 255,
        hue_to_rgb(first, second, hue) * 255,
        hue_to_rgb(first, second, hue - 1 / 3) * 255
end

local function adjust_lightness(hex, delta, name)
    local red, green, blue = parse(hex)
    local hue, saturation, lightness = rgb_to_hsl(red, green, blue)
    local factor = amount(delta, name)
    if name == "lighten amount" then
        lightness = lightness + (1 - lightness) * factor
    else
        lightness = lightness * (1 - factor)
    end
    return encode(hsl_to_rgb(hue, saturation, lightness))
end

function M.lighten(hex, delta)
    return adjust_lightness(hex, delta, "lighten amount")
end

function M.darken(hex, delta)
    return adjust_lightness(hex, delta, "darken amount")
end

function M.is_dark(hex)
    local red, green, blue = parse(hex)
    local function linear(channel)
        channel = channel / 255
        if channel <= 0.04045 then
            return channel / 12.92
        end
        return ((channel + 0.055) / 1.055) ^ 2.4
    end
    local luminance = 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    return luminance < 0.5
end

return M
