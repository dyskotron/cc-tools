local colorUtils = {}

function colorUtils.resetTerminalPalette()
    -- Reset palette to default
    term.setPaletteColour(colors.white, 0xFFFFFF)
    term.setPaletteColour(colors.black, 0x000000)
    term.setPaletteColour(colors.orange, 0xFFA500)
    term.setPaletteColour(colors.magenta, 0xFF00FF)
    term.setPaletteColour(colors.lightBlue, 0xADD8E6)
    term.setPaletteColour(colors.yellow, 0xFFFF00)
    term.setPaletteColour(colors.lime, 0x00FF00)
    term.setPaletteColour(colors.pink, 0xFFC0CB)
    term.setPaletteColour(colors.gray, 0x808080)
    term.setPaletteColour(colors.lightGray, 0xD3D3D3)
    term.setPaletteColour(colors.cyan, 0x00FFFF)
    term.setPaletteColour(colors.purple, 0x800080)
    term.setPaletteColour(colors.blue, 0x0000FF)
    term.setPaletteColour(colors.brown, 0xA52A2A)
    term.setPaletteColour(colors.green, 0x008000)
    term.setPaletteColour(colors.red, 0xFF0000)
end

function colorUtils.setPaletteColorRGB(colorId, r, g, b)
    -- Convert RGB (0-255) to normalized RGB (0-1) and pack into a hex value
    local hexColor = colors.packRGB(r / 255, g / 255, b / 255)
    term.setPaletteColour(colorUtils.colorIdToTerminalId(colorId), hexColor)
end

function colorUtils.colorIdToTerminalId(colorId)
    --todo safeguard max index is 14
    return colorUtils.indexToCCColor(colorId + 2)
end

function colorUtils.indexToCCColor(index)
    if index < 1 or index > 16 then
        error("Index must be between 1 and 16")
    end
    return 2 ^ (index - 1)
end

return colorUtils
