--------------------------------------------------------------------------
-- PROGRESS BAR
--------------------------------------------------------------------------
local progressBar = {}

-- Renders a progress bar in the middle of the screen.
-- progress: 0..1 (0%..100%)
-- message: short string describing what's happening
function progressBar.render(progress, message)
    -- Always clear before drawing the "frame"
    term.clear()
    term.setCursorPos(1, 1)

    local w, h = term.getSize()

    -- Position message in the middle (slightly above the bar)
    local msgX = math.floor((w - #message) / 2) + 1
    local msgY = math.floor(h / 2) - 1
    term.setCursorPos(msgX, msgY)
    term.write(message)

    -- Build the progress bar
    local barWidth = 30
    local filled = math.floor(progress * barWidth)
    local bar = string.rep("=", filled) .. string.rep("-", barWidth - filled)

    -- Center the bar
    local barX = math.floor((w - (barWidth + 2)) / 2) + 1 -- brackets [ ]
    local barY = msgY + 1
    term.setCursorPos(barX, barY)
    term.write("[" .. bar .. "]")

    -- Show numeric percentage
    local percent = math.floor(progress * 100)
    term.write(" " .. percent .. "%")
end

return progressBar