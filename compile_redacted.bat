@echo off
cls
color 2
echo.
echo - Starting compiling process...

set numberOf=3
if exist "build" (
    echo - \build directory already exists, continuing...
) else (
    mkdir "build"
    echo - build\ created.
)
type "main.gsc" >> "build\final_redacted.gsc"
echo - Adding file 1/%numberOf%
type "mods\zm_hitmarkers.gsc" >> "build\final_redacted.gsc"
echo - Adding file 2/%numberOf%
type "mods\zm_killcam.gsc" >> "build\final_redacted.gsc"
echo - Adding file 3/%numberOf%
type "mods\zm_pvp.gsc" >> "build\final_redacted.gsc"
echo - Generated build\final.gsc file.
del /f "C:\Games\Black Ops 2\data\scripts\final_redacted.gsc"
xcopy /c /f "build\final_redacted.gsc" "C:\Games\Black Ops 2\data\scripts\" /Y
del /f "build\final_redacted.gsc"
pause
cls
color 7