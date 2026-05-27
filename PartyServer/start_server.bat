@echo off
echo Starting servers...

REM Kaynnista Node serveri uuteen ikkunaan
start cmd /k "node server.js"

REM Kaynnista Python HTTP serveri uuteen PowerShell-ikkunaan
start powershell -NoExit -Command "python -m http.server 8000"

echo Ready!
pause