local stringUtils = {}

function stringUtils.trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

-- URL Encoding in Lua
function stringUtils.urlEncode(str)
    return (str:gsub("[^%w_%-%.~]", function(c)
        return string.format("%%%02X", string.byte(c))
    end))
end

-- Re-define urlEncode to handle spaces (todo: do i need this one still?)
function stringUtils.urlEncodeWithSpaces(str)
    return str:gsub("([^%w %-%_%.%~])", function(c)
        return string.format("%%%02X", string.byte(c))
    end):gsub(" ", "+")
end

-- URL Decoding in Lua
function stringUtils.urlDecode(str)
    return (str:gsub("%%(%x%x)", function(hex)
        return string.char(tonumber(hex, 16))
    end))
end

function stringUtils.getSimplifiedName(fullName)
    local _, _, simpleName = string.find(fullName, ":(.+)")
    return simpleName or fullName
end

function stringUtils.tableToString(t, indent)
    indent = indent or 0
    local indentString = string.rep(" ", indent)
    local result = ""

    for key, value in pairs(t) do
        if type(value) == "table" then
            result = result .. indentString .. tostring(key) .. ":\n"
            result = result .. stringUtils.tableToString(value, indent + 1)
        else
            result = result .. indentString .. tostring(key) .. ": " .. tostring(value) .. "\n"
        end
    end

    return result
end

return stringUtils