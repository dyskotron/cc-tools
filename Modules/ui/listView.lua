require("Modules.ui.view")

-- ListView Class (inherits from View)
local ListView = {}
ListView.__index = ListView
setmetatable(ListView, { __index = View }) -- Ensure ListView inherits from View

-- Override Init for ListView
function ListView:Init(x, y, width, height, char)
    local obj = View.Init(self, x, y, width, height, char) -- Call parent Init
    obj.data = {} -- Initialize an empty data table
    obj.selectedIndex = nil -- No item selected initially
    obj.scrollOffset = 0 -- Starting offset for scrolling
    obj.textColor = colors.white -- Default text color
    obj.highlightColor = colors.lightGray -- Default highlight background color
    obj.backgroundColor = colors.black -- Default background color
    return setmetatable(obj, ListView) -- Set metatable to ListView
end

-- Set data for the ListView and render it
function ListView:setData(data)
    self.data = data
    self.selectedIndex = nil -- Reset selection to none
    self.scrollOffset = 0 -- Reset scroll offset
    self:render()
end

-- Select a specific index
function ListView:select(index)
    if index == nil or (index >= 1 and index <= #self.data) then
        self.selectedIndex = index

        -- Adjust scroll offset if the selected item is out of view
        if self.selectedIndex and self.selectedIndex < self.scrollOffset + 1 then
            self.scrollOffset = self.selectedIndex - 1
        elseif self.selectedIndex and self.selectedIndex > self.scrollOffset + self.height then
            self.scrollOffset = self.selectedIndex - self.height
        end

        self:render()
    end
end

-- Select an index relative to the current one
function ListView:selectRelative(diff)
    if self.selectedIndex == nil then
        -- If no selection, select the first item when moving
        self:select(1)
    else
        local newIndex = self.selectedIndex + diff
        self:select(math.max(1, math.min(#self.data, newIndex))) -- Clamp index to valid range
    end
end

-- Render the ListView, highlighting the selected item
function ListView:render()
    self:clear() -- Clear the view area
    for i = 1, self.height do
        local dataIndex = i + self.scrollOffset
        if dataIndex > #self.data then
            break -- No more data to render
        end

        local text = tostring(self.data[dataIndex]):sub(1, self.width) -- Ensure the text fits within the width
        if dataIndex == self.selectedIndex then
            -- Highlight the selected row by filling it entirely
            term.setBackgroundColor(self.highlightColor)
            term.setTextColor(self.textColor)
            self:write(1, i, text .. string.rep(" ", self.width - #text))
        else
            -- Normal background and text colors
            term.setBackgroundColor(self.backgroundColor)
            term.setTextColor(self.textColor)
            self:write(1, i, text)
        end
    end
    -- Reset terminal colors to default
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
end

return ListView