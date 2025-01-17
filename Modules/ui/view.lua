-- View Class
local View = {}
View.__index = View

-- Initialize a new View
function View:Init(x, y, width, height, char)
    local obj = setmetatable({}, View)
    obj.x = x
    obj.y = y
    obj.width = width
    obj.height = height
    obj.fillChar = char or " "
    obj:clear()
    return obj
end

-- Clear the View's area
function View:clear()
    for i = 0, self.height - 1 do
        term.setCursorPos(self.x, self.y + i)
        term.write(string.rep(self.fillChar, self.width))
    end
end

-- Write text within the View's area
function View:write(x, y, text)
    if x < 1 or x > self.width or y < 1 or y > self.height then
        return -- Out of bounds
    end

    local writeX = self.x + x - 1
    local writeY = self.y + y - 1

    term.setCursorPos(writeX, writeY)
    term.write(text:sub(1, self.width - x + 1))
end

-- Print text within the View's area
function View:print(text)
    for i = 1, #text, self.width do
        local line = text:sub(i, i + self.width - 1)
        if i / self.width > self.height then
            break -- Stop if we run out of space
        end
        self:write(1, math.ceil(i / self.width), line)
    end
end

return View