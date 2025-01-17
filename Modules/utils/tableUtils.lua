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

return tableUtils