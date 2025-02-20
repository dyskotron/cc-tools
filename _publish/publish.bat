@echo off

:: Run the upload script
call python -u "upload_files.py"

:: Check if the script executed successfully
if %errorlevel% == 0 (
    echo Upload script executed successfully.
) else (
    echo Error: Upload script encountered an issue.
)

pause