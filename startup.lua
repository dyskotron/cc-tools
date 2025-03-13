textFileUtil = require("Modules.utils.textFileUtil")
stringUtils = require("Modules.utils.stringUtils")

-- fileHandle = fs.open("startupAction", "r")
-- print(stringUtils.tableToString(fileHandle))

action = textFileUtil.readFile("startupAction")

if(action == nil) then
    print("well there is nothing to do")
else
    print("yo!, we have action to do!")
    print(action)
    shell.run(action)
end