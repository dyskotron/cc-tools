@echo off
setlocal

:: Path to the virtual environment
set VENV_PATH=venv

:: Path to the Python upload script
set UPLOAD_SCRIPT=upload_files.py

:: Check if the virtual environment exists
if not exist "%VENV_PATH%" (
    echo Error: Virtual environment not found at %VENV_PATH%.
    exit /b 1
)

:: Activate the virtual environment
call "%VENV_PATH%\Scripts\activate.bat"

:: Run the upload script
python -u "%UPLOAD_SCRIPT%"

:: Check if the script executed successfully
if %errorlevel% == 0 (
    echo Upload script executed successfully.
) else (
    echo Error: Upload script encountered an issue.
)

:: Deactivate the virtual environment
deactivate

endlocal
pause