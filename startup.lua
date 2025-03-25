textFileUtil = require("Modules.utils.textFileUtil")
stringUtils = require("Modules.utils.stringUtils")
	f4476acd-1ced-3b2c-b2bc-fb3110e1045e

-- fileHandle = fs.open("startupAction", "r")
-- print(stringUtils.tableToString(fileHandle))

startupActionFile = "startupAction"


if(fs.exists(startupActionFile)) then
    action = textFileUtil.readFile("startupAction")
    print("yo!, we have action to do!")
    print(action)
    shell.run(action)
else
    print("well there is nothing to do, so .. welcome i guess")
end