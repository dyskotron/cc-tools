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
        if byte L��[���[�
��ۋPT��RH�\�X�\���[����]JB�[��[����[K����J
B��KH�\�M�[���HH�[H�۝[�X[�X[B���[[���Y�۝[�H�\�M��[���J�۝[�
B��K[��Y\��Y�J��۝[������۝[�
B�K[��Y\��Y�J��\�M�Y[���Y�۝[�����[���Y�۝[�
B��KHT�[���HH�[[�[YH�]��H�۝[����[[���Y�[[�[YHH\�[���J�[[�[YJB��KH�\\�HH��]H
ۛH�\�M�Y[���Y�۝[���T�[���Y
B���[]HH��[[�[YOH���[���Y�[[�[YH����]OH���[���Y�۝[���KH��H��]H�܈X�Y��[���Y\��Y�J���]N����]JB��KHܙX]HH���\]Y\�[��[�H�[H�H�\��\����[\�H�T��T��T����\�Y�KH�\X�H�]H�ܜ�X��\��\�T���[XY\��HȐ�۝[�U\H�HH�\X�][ۋ�]���Y�ܛK]\�[���Y��Ȑ�۝[�S[���HH���[���]JB�B����Y\��Y�J��[�[�����\]Y\�����B���[�\�ۜ�K�]\���HH���
\�]KXY\��B�Y��\�ۜ�H[����Y\��Y�J��\�ۜ�H��N�������[���]\���JJHKH���\�ۜ�H��B���Y\��Y�J��[H\�YY�X��\�ٝ[N�����[[�[YJB�[�B���Y\��Y�J�\��܎��Z[Y�\�Y����[[�[YJB���Y\��Y�J��]\���N����
���[���]\���JH܈�[�ۛ�ۈ�JB�[��[���KH�[��[ۈ�\�Y[�XH�[\�
^�Y[��H���H���\�B��[��[ۈ\�Y[�[\�
B���[�[\�H�˛\�
�ȊHKH\�H�[\�[�H���\�X�ܞB��Y����[\�[����[\��ܓ\��H�\��܎�[�X�H�\��[\�[�H���\�X�ܞH����Y\��Y�J\��ܓ\��B��]\���[�����[\�YY�[\�H�B���܈��[[�[YH[�\Z\���[\�HKH��\H���H���\�[�ۛH\�Y�XH�[\Y��[[�[YH�H���H�[��Y���[�˛X]�
�[[�[YK�K�XI�H[��\�Y�[J�[[�[YJB�X�K�[��\�
\�YY�[\��[[�[YJB�[�ZY��˚\�\��[[�[YJH[��KH�X�\��]�[H\�Y�[\�[��X�\�X�ܚY\�
��\���H���\�B�\�Y[�[\�[�\�X�ܞJ�[[�[YK\�YY�[\�B�[��[��[����]\��\�YY�[\[���KH�[��[ۈ���[��X�\�X�ܚY\�[�\�Y�XH�[\�
^�Y[�����H�B��[��[ۈ\�Y[�[\�[�\�X�ܞJ\�X�ܞK\�YY�[\�B���[�[\�H�˛\�
\�X�ܞJB��Y����[\�[����[\��ܓ\��H�\��܎�[�X�H�\��[\�[�\�X�ܞN����\�X�ܞB���Y\��Y�J\��ܓ\��B��]\���[����܈��[[�[YH[�\Z\���[\�HKH��\H���H���\�[�ۛH\�Y�XH�[\Y��[[�[YH�'&��"F�V��b7G&��r��F6��f��V��R�"R��VB"�F�V�W��Df��R�F�&V7F�'���"�"��f��V��R��F&�R��6W'B�W��FVDf��W2�F�&V7F�'���"�"��f��V��R��V�6V�bg2�4F�"�F�&V7F�'���"�"��f��V��R�F�V���&V7W'6�fVǒ66�7V&F�&V7F�&�W0�W��D��f��W4��F�&V7F�'��F�&V7F�'���"�"��f��V��R�W��FVDf��W2��V�@�V�@�V�@�V�@����gV�7F���F�F�v���Bf��P�gV�7F���F�v���Df��R�f��V��R����6�W&��4U%dU%�U$���D�t���E�D���#�f��V��S�"��f��V��P���6�&W7��6R��GG�vWB�W&��b&W7��6RF�V���6�FF�&W7��6R�&VD���&W7��6R�6��6R������W�G&7BF�RF�&V7F�'�g&��F�Rf��V��P���6�F�"�g2�vWDF�"�f��V��R����t�W76vR�'F&vWBF�&V7F�'��"��F�"���b��Bg2�W��7G2�F�"�F�V���7&VFRF�RF�&V7F�'��b�BF�W6�wBW��7@�g2���TF�"�F�"����t�W76vR�&7&VF��rF�&V7F�'��"��F�"��V�@�����V�F�Rf��Rf�"w&�F��p���6�f��R�g2��V�f��V��R�'r"���bf��RF�V�f��R�w&�FR�FF��f��R�6��6R�����t�W76vR�$F�v���FVC�"��f��V��R��V�6P���t�W76vR�$f��VBF�w&�FR"��f��V��R��V�@�V�6P���t�W76vR�$f��VBF�F�v���B"��f��V��R��V�@�V�@����gV�7F���F�F�v���B��f��W0�gV�7F���F�v���D��f��W2�W��FVDf��W2��f�"��f��V��R����'2�W��FVDf��W2�F�F�v���Df��R�f��V��R��V�@�V�@��gV�7F���G&�҇2��&WGW&��3�w7V"�%�W2���ҒW2�B"�"S"���V�@��gV�7F�����ₐ��6�V$��tf��R������66W76��r&wV�V�G0���6�&w2��Т�b6&r�F�V�f�"��b����'2�&r�F�F&�R��6W'B�&w2�b��V�@�V�@���b&w5����'W"F�V���W��Bf��W0���t�W76vR�%7��27F'FVB�W��F��rf��W2�����"����6�W��FVDf��W2�W��D��f��W2�����b7W��FVDf��W2�F�V���t�W76vR�%7��26���WFVB�f��W2W��FVB���"��V�6P���t�W76vR�$W'&�#���f��W2W��FVB���"��V�@�V�6P���F�v���Bf��W0���t�W76vR�%7��27F'FVB�F�v���F��rf��W2�����"�����vWBƗ7B�bf��W2F�F�v���B�g&��F�R6W'fW"����6�W&��4U%dU%�U$���"�f��W2 ���6�&W7��6R��GG�vWB�W&���b&W7��6RF�V���6�&u�FF�&W7��6R�&VD����vWBF�R&r&W7��6RFF�&W7��6R�6��6R��������rF�R&r&W7��6Rf�"FV'Vvv��p���t�W76vR�%6W'fW"&W7��6S�"��&u�FF��%��"�����'6RF�R6����6W&FVBƗ7B�bf��W0���6�f��W2��Тf�"f��V��R��&u�FF�v�F6��"����Ҳ�"�F�f��V��R�G&�҆f��V��R���&V��fR�VF��r�G&�Ɩ�r76W0�F&�R��6W'B�f��W2�f��V��R��V�@����6�V6��bvf��W2r�2fƖ@��bf��W2F�V�f�"��f��V��R����'2�f��W2�F���t�W76vR�$F�v���F��r"��f��V��R��"�����"�����F�v���BV6�f��P���6�F�v���E�W&��4U%dU%�U$���"�F�v���B�"��f��V��P���6�f��U�&W7��6R��GG�vWB�F�v���E�W&���bf��U�&W7��6RF�V���6�FF�f��U�&W7��6R�&VD���f��U�&W7��6R�6��6R������6fRF�Rf��R��6�ǐ���6�f��R�g2��V�f��V��R�'r"���bf��RF�V�f��R�w&�FR�FF��f��R�6��6R�����t�W76vR�$f��R"��f��V��R��"F�v���FVB7V66W76gV�ǒ���"��V�6P���t�W76vR�$f��VBF�w&�FR"��f��V��R��"���"��V�@�V�6P���t�W76vR�$W'&�#�V�&�RF�F�v���B"��f��V��R��"���"��V�@�V�@�V�6P���t�W76vR�$W'&�#���fƖBf��RƗ7B&V6V�fVBg&��6W'fW"���"��V�@�V�6P���t�W76vR�$W'&�#�V�&�RF�fWF6�F�Rf��RƗ7Bg&��F�R6W'fW"���"��V�@�V�@�V�@����'V�F�R���gV�7F�����ₐ