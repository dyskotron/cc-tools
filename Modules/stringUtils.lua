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



return stringUtils