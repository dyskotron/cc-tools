local base64 = require("Modules.base64")

-- Configuration
local SERVER_URL = "http://localhost:8000/"  -- Change to the correct IP if needed
local DOWNLOAD_PATH = "/download"           -- Path for downloading files
local UPLOAD_PATH = "/upload"               -- Path for uploading files
local LOG_FILE = "sync_log.log"             -- Log file for syncing attempts

-- Function to log messages to the log file
function logMessage(message)
    -- Open the log file in append mode to avoid clearing the contents
    local logFile = fs.open(LOG_FILE, "a")
    if logFile then
        logFile.write(message .. "\n")  -- Add newline for better formatting
        logFile.close()
    else
        print("Error: Unable to open log file.")
    end

    print(message)
end

-- URL Encoding in Lua
function urlEncode(str)
    return (str:gsub("[^%w_%-%.~]", function(c)
        return string.format("%%%02X", string.byte(c))
    end))
end

-- URL Decoding in Lua
function urlDecode(str)
    return (str:gsub("%%(%x%x)", function(hex)
        return string.char(tonumber(hex, 16))
    end))
end

-- Function to explicitly clear the contents of the log file
function clearLogFile()
    local logFile = fs.open(LOG_FILE, "w")  -- Open in write mode to clear the file
    if logFile then
        logFile.close()  -- Just close the file to clear its contents
    else
        logMessage("Error: Unable to open log file.")
    end
end

function table.contains(tbl, value)
    for _, v in ipairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end

-- Function to URL encode data
function urlEncode(str)
    return str:gsub("([^%w %-%_%.%~])", function(c)
        return string.format("%%%02X", string.byte(c))
    end):gsub(" ", "+")
end

-- Function to upload a file to the server (with manual Base64 encoding and URL encoding)
function uploadFile(filename)
    logMessage("Preparing to upload file: " .. filename)

    local file = fs.open(filename, "r")
    if not file then
        logMessage("Error: Could not open file " .. filename)
        return
    end

    local content = file.readAll()

    -- Log the file size
        logMessage("File size: " .. #content .. " bytes")

    -- Check for non-ASCII characters
    for i = 1, #content do
        local byte = string.byte(content, i)
        if byte LÈ[‚ˆš[
“›Û‹PTĞÒRHÚ\˜Xİ\ˆ›İ[™ˆ‹]JBˆ[™ˆ[™‚ˆš[K˜ÛÜÙJ
B‚ˆKH˜\ÙM[˜ÛÙHHš[HÛÛ[X[X[BˆØØ[[˜ÛÙYÛÛ[H˜\ÙM™[˜ÛÙJÛÛ[
B‚ˆK[ÙÓY\ÜØYÙJ˜ÛÛ[ˆˆ‹ˆÛÛ[
BˆK[ÙÓY\ÜØYÙJ˜\ÙMY[˜ÛÙYÛÛ[ˆˆ‹ˆ[˜ÛÙYÛÛ[
B‚ˆKHT“[˜ÛÙHHš[[˜[YH]“ÕHÛÛ[ˆØØ[[˜ÛÙYš[[˜[YHH\›[˜ÛÙJš[[˜[YJB‚ˆKH™\\™HHÔÕ]H
Û›H˜\ÙMY[˜ÛÙYÛÛ[›İT“[˜ÛÙY
BˆØØ[]HH™š[[˜[YOHˆ‹ˆ[˜ÛÙYš[[˜[YH‹ˆ‰™]OHˆ‹ˆ[˜ÛÙYÛÛ[‚ˆKHÙÈHÔÕ]H›ÜˆXYÙÚ[™ÂˆÙÓY\ÜØYÙJ”ÔÕ]Nˆˆ‹ˆ]JB‚ˆKHÜ™X]HHÔÕ™\]Y\İ[™Ù[™Hš[HÈHÙ\™\‚ˆØØ[\›HÑT•‘T—ÕT“‹ˆ\ØYˆKH™\XÙHÚ]HÛÜœ™XİÙ\™\ˆTˆØØ[XY\œÈHÂˆÈÛÛ[U\H—HH˜\XØ][Û‹Ş]İİËY›Ü›K]\›[˜ÛÙY‹ˆÈÛÛ[S[™İ—HHÜİš[™ÊÙ]JBˆB‚ˆÙÓY\ÜØYÙJ”Ù[™[™ÈÔÕ™\]Y\İ‹‹ˆŠBˆØØ[™\ÜÛœÙKİ]\ĞÛÙHHœÜİ
\›]KXY\œÊBˆYˆ™\ÜÛœÙH[‚ˆÙÓY\ÜØYÙJ”™\ÜÛœÙHÛÙNˆˆ‹ˆÜİš[™Êİ]\ĞÛÙJJHKHÙÈ™\ÜÛœÙHÛÙBˆÙÓY\ÜØYÙJ‘š[H\ØYYİXØÙ\ÜÙ[Nˆˆ‹ˆš[[˜[YJBˆ[ÙBˆÙÓY\ÜØYÙJ‘\œ›Üˆ˜Z[YÈ\ØYˆ‹ˆš[[˜[YJBˆÙÓY\ÜØYÙJ”İ]\ÈÛÙNˆˆ‹ˆ
Üİš[™Êİ]\ĞÛÙJHÜˆ•[šÛ›İÛˆŠJBˆ[™™[™‚‹KH[˜İ[ÛˆÈ\ØY[›XHš[\È
^ÛY[™ÈHœ›ÛHˆ›Û\ŠB™[˜İ[Ûˆ\ØY[š[\Ê
BˆØØ[š[\ÈHœË›\İ
‹ÈŠHKH\İHš[\È[ˆH›Ûİ\™XİÜB‚ˆYˆ›İš[\È[‚ˆØØ[\œ›Ü“\ÙÈH‘\œ›Üˆ[˜X›HÈ\İš[\È[ˆH›Ûİ\™XİÜH‚ˆÙÓY\ÜØYÙJ\œ›Ü“\ÙÊBˆ™]\›‚ˆ[™‚ˆØØ[\ØYYš[\ÈHßB‚ˆ›ÜˆËš[[˜[YH[ˆ\Z\œÊš[\ÊHÂˆKHÚÚ\Hœ›ÛHˆ›Û\ˆ[™Û›H\ØY›XHš[\ÂˆYˆš[[˜[YHHœ›ÛHˆ[‚ˆYˆİš[™Ë›X]Ú
š[[˜[YK‰K›XIŠH[‚ˆ\ØYš[Jš[[˜[YJBˆX›Kš[œÙ\
\ØYYš[\Ëš[[˜[YJBˆ[ÙZYˆœËš\Ñ\Šš[[˜[YJH[‚ˆKH™Xİ\œÚ]™[H\ØYš[\È[ˆİX™\™XİÜšY\È
ÚÚ\œ›ÛHˆ›Û\ŠBˆ\ØY[š[\Ò[‘\™XİÜJš[[˜[YK\ØYYš[\ÊBˆ[™ˆ[™ˆ[™‚ˆ™]\›ˆ\ØYYš[\Â™[™‚‹KH[˜İ[ÛˆÈØØ[ˆİX™\™XİÜšY\È[™\ØY›XHš[\È
^ÛY[™Èœ›ÛHŠB™[˜İ[Ûˆ\ØY[š[\Ò[‘\™XİÜJ\™XİÜK\ØYYš[\ÊBˆØØ[š[\ÈHœË›\İ
\™XİÜJB‚ˆYˆ›İš[\È[‚ˆØØ[\œ›Ü“\ÙÈH‘\œ›Üˆ[˜X›HÈ\İš[\È[ˆ\™XİÜNˆˆ‹ˆ\™XİÜBˆÙÓY\ÜØYÙJ\œ›Ü“\ÙÊBˆ™]\›‚ˆ[™‚ˆ›ÜˆËš[[˜[YH[ˆ\Z\œÊš[\ÊHÂˆKHÚÚ\Hœ›ÛHˆ›Û\ˆ[™Û›H\ØY›XHš[\ÂˆYˆš[[˜[YHÒ'&öÒ"F†Và¢–b7G&–æræÖF6‚†f–ÆVæÖRÂ"RæÇVB"’F†Và¢WÆöDf–ÆR†F—&V7F÷'’ââ"ò"ââf–ÆVæÖR¢F&ÆRæ–ç6W'B‡WÆöFVDf–ÆW2ÂF—&V7F÷'’ââ"ò"ââf–ÆVæÖR¢VÇ6V–bg2æ—4F—"†F—&V7F÷'’ââ"ò"ââf–ÆVæÖR’F†Và¢ÒÒ&V7W'6—fVÇ’66â7V&F—&V7F÷&–W0¢WÆöDÆÄf–ÆW4–äF—&V7F÷'’†F—&V7F÷'’ââ"ò"ââf–ÆVæÖRÂWÆöFVDf–ÆW2¢Væ@¢Væ@¢Væ@¦Væ@ ¢ÒÒgVæ7F–öâFòF÷væÆöBf–ÆP¦gVæ7F–öâF÷væÆöDf–ÆR†f–ÆVæÖR¢Æö6ÂW&ÂÒ4U%dU%õU$ÂââDõtäÄôEõD‚ââ#öf–ÆVæÖSÒ"ââf–ÆVæÖP¢Æö6Â&W7öç6RÒ‡GGævWB‡W&Â¢–b&W7öç6RF†Và¢Æö6ÂFFÒ&W7öç6Rç&VDÆÂ‚¢&W7öç6Ræ6Æ÷6R‚ ¢ÒÒW‡G&7BF†RF—&V7F÷'’g&öÒF†Rf–ÆVæÖP¢Æö6ÂF—"Òg2ævWDF—"†f–ÆVæÖR¢ÆötÖW76vR‚'F&vWBF—&V7F÷'“¢"ââF—"¢–bæ÷Bg2æW†—7G2†F—"’F†Và¢ÒÒ7&VFRF†RF—&V7F÷'’–b—BFöW6âwBW†—7@¢g2æÖ¶TF—"†F—"¢ÆötÖW76vR‚&7&VF–ærF—&V7F÷'“¢"ââF—"¢Væ@ ¢ÒÒ÷VâF†Rf–ÆRf÷"w&—F–æp¢Æö6Âf–ÆRÒg2æ÷Vâ†f–ÆVæÖRÂ'r"¢–bf–ÆRF†Và¢f–ÆRçw&—FR†FF¢f–ÆRæ6Æ÷6R‚¢ÆötÖW76vR‚$F÷væÆöFVC¢"ââf–ÆVæÖR¢VÇ6P¢ÆötÖW76vR‚$f–ÆVBFòw&—FR"ââf–ÆVæÖR¢Væ@¢VÇ6P¢ÆötÖW76vR‚$f–ÆVBFòF÷væÆöB"ââf–ÆVæÖR¢Væ@¦Væ@ ¢ÒÒgVæ7F–öâFòF÷væÆöBÆÂf–ÆW0¦gVæ7F–öâF÷væÆöDÆÄf–ÆW2‡WÆöFVDf–ÆW2¢f÷"òÂf–ÆVæÖR–â——'2‡WÆöFVDf–ÆW2’Fğ¢F÷væÆöDf–ÆR†f–ÆVæÖR¢Væ@¦Væ@ ¦gVæ7F–öâG&–Ò‡2¢&WGW&â‡3¦w7V"‚%âW2¢‚âÒ’W2¢B"Â"S"’¦Væ@ ¦gVæ7F–öâÖ–â‚ ¢6ÆV$Æötf–ÆR‚ ¢ÒÒ66W76–ær&wVÖVçG0¢Æö6Â&w2Ò·Ğ¢–b6&râF†Và¢f÷"’Âb–â——'2†&r’Fğ¢F&ÆRæ–ç6W'B†&w2Âb¢Væ@¢Væ@ ¢–b&w5³ÒÓÒ'W"F†Và¢ÒÒWÆöBf–ÆW0¢ÆötÖW76vR‚%7–æ27F'FVBâWÆöF–ærf–ÆW2ââåÆâ"¢Æö6ÂWÆöFVDf–ÆW2ÒWÆöDÆÄf–ÆW2‚ ¢–b7WÆöFVDf–ÆW2âF†Và¢ÆötÖW76vR‚%7–æ26ö×ÆWFVBâf–ÆW2WÆöFVBåÆâ"¢VÇ6P¢ÆötÖW76vR‚$W'&÷#¢æòf–ÆW2WÆöFVBåÆâ"¢Væ@¢VÇ6P¢ÒÒF÷væÆöBf–ÆW0¢ÆötÖW76vR‚%7–æ27F'FVBâF÷væÆöF–ærf–ÆW2ââåÆâ" ¢ÒÒvWBÆ—7Böbf–ÆW2FòF÷væÆöB†g&öÒF†R6W'fW"¢Æö6ÂW&ÂÒ4U%dU%õU$Âââ"öf–ÆW2 ¢Æö6Â&W7öç6RÒ‡GGævWB‡W&Â ¢–b&W7öç6RF†Và¢Æö6Â&uöFFÒ&W7öç6Rç&VDÆÂ‚’ÒÒvWBF†R&r&W7öç6RFF¢&W7öç6Ræ6Æ÷6R‚ ¢ÒÒÆörF†R&r&W7öç6Rf÷"FV'Vvv–æp¢ÆötÖW76vR‚%6W'fW"&W7öç6S¢"ââ&uöFFââ%Æâ" ¢ÒÒ'6RF†R6öÖÖ×6W&FVBÆ—7Böbf–ÆW0¢Æö6Âf–ÆW2Ò·Ğ¢f÷"f–ÆVæÖR–â&uöFF¦vÖF6‚‚"…µâÅÒ²’"’Fğ¢f–ÆVæÖRÒG&–Ò†f–ÆVæÖR’ÒÒ&VÖ÷fRÆVF–ær÷G&–Æ–ær76W0¢F&ÆRæ–ç6W'B†f–ÆW2Âf–ÆVæÖR¢Væ@ ¢ÒÒ6†V6²–bvf–ÆW2r—2fÆ–@¢–bf–ÆW2F†Và¢f÷"òÂf–ÆVæÖR–â——'2†f–ÆW2’Fğ¢ÆötÖW76vR‚$F÷væÆöF–ær"ââf–ÆVæÖRââ"ââåÆâ" ¢ÒÒF÷væÆöBV6‚f–ÆP¢Æö6ÂF÷væÆöE÷W&ÂÒ4U%dU%õU$Âââ"öF÷væÆöBò"ââf–ÆVæÖP¢Æö6Âf–ÆU÷&W7öç6RÒ‡GGævWB†F÷væÆöE÷W&Â ¢–bf–ÆU÷&W7öç6RF†Và¢Æö6ÂFFÒf–ÆU÷&W7öç6Rç&VDÆÂ‚¢f–ÆU÷&W7öç6Ræ6Æ÷6R‚ ¢ÒÒ6fRF†Rf–ÆRÆö6ÆÇ¢Æö6Âf–ÆRÒg2æ÷Vâ†f–ÆVæÖRÂ'r"¢–bf–ÆRF†Và¢f–ÆRçw&—FR†FF¢f–ÆRæ6Æ÷6R‚¢ÆötÖW76vR‚$f–ÆR"ââf–ÆVæÖRââ"F÷væÆöFVB7V66W76gVÆÇ’åÆâ"¢VÇ6P¢ÆötÖW76vR‚$f–ÆVBFòw&—FR"ââf–ÆVæÖRââ"åÆâ"¢Væ@¢VÇ6P¢ÆötÖW76vR‚$W'&÷#¢Væ&ÆRFòF÷væÆöB"ââf–ÆVæÖRââ"åÆâ"¢Væ@¢Væ@¢VÇ6P¢ÆötÖW76vR‚$W'&÷#¢–çfÆ–Bf–ÆRÆ—7B&V6V—fVBg&öÒ6W'fW"åÆâ"¢Væ@¢VÇ6P¢ÆötÖW76vR‚$W'&÷#¢Væ&ÆRFòfWF6‚F†Rf–ÆRÆ—7Bg&öÒF†R6W'fW"åÆâ"¢Væ@¢Væ@¦Væ@ ¢ÒÒ'VâF†RÖ–âgVæ7F–öà¦Ö–â‚