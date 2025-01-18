local stringUtils = require("Modules.utils.stringUtils")
local logger = require("Modules.utils.logger")
local ListView = require("Modules.ui.listView")


logger.init(true, true, true, "monitorTest.log")
local w, h = term.getSize()
term.clear()

local leftList = ListView:Init(1, 1, w / 2, h, " ")
local rightList = ListView:Init(w / 2 + 1, 1, w / 2, h, " ")
local activeList = leftList


local termMethods = {}

term.print(stringUtils.tableToString(term))

for key, value in pairs(term) do
        table.insert(termMethods, value)
end

local monitorDeviceName = peripherals.find("Monitor")
logger.info(monitorDeviceName)


rightList:setData(peripherals.getMethods(monitorDeviceName))
leftList:setData(termMethods)

while true do
    local event, key = os.pullEvent("key") -- Wait for a key event

    if key == keys.tab then
        -- Store the last selected index for the current active list
        if activeList == leftList then

           activeList = rightList
        else
           activeList = leftList
        end

    elseif key == keys.up then
        activeList:selectRelative(-1) -- Move selection up in the active list
    elseif key == keys.down then
        activeList:selectRelative(1) -- Move selection down in the active list
    end
end