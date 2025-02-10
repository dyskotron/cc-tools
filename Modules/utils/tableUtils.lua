local tableUtils = {}

function tableUtils.concatenateTables(...)
    local result = {}
    for _, tbl in ipairs({...}) do
        for _, value in ipairs(tbl) do
            table.insert(result, value)
        end
    end
    return result
end

function tableUtils.tableLength(table)
    local count = 0
    for _ in pairs(table) do count = count + 1 end
    return count
end

return tableUtils