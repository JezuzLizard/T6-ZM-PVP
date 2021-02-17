@echo off
cls
color 2
echo.
echo - Starting compiling process...

set numberOf=4
if exist "build" (
    echo - \build directory already exists, continuing...
) else (
    mkdir "build"
    echo - build\ created.
)
type "main.gsc" >> "build\final.gsc"
echo - Adding file 1/%numberOf%
type "mods\zm_hitmarkers.gsc" >> "build\final.gsc"
echo - Adding file 2/%numberOf%
type "mods\zm_killcam.gsc" >> "build\final.gsc"
echo - Adding file 3/%numberOf%
type "mods\zm_pvp.gsc" >> "build\final.gsc"
echo - Adding file 4/%numberOf%
type "mods\zm_player_spawning.gsc" >> "build\final.gsc"
echo - Generated build\final.gsc file.
timeout /t 2 /nobreak > NUL

if exist "resources\compiler\Compiler.exe" (
    if exist "resources\compiler\Irony.dll" (
        echo - Compiling build\final.gsc...
        echo.
        "resources\compiler\Compiler.exe" "build\final.gsc"
        xcopy /c /f "final-compiled.gsc" "build\" /Y
        del /f "final-compiled.gsc"
        ren "build\final-compiled.gsc" "_clientids.gsc"
        del /f "build\final.gsc"
        if exist "build\maps\mp\gametypes_zm" (
            if exist "build\maps\mp\gametypes_zm\_clientids.gsc" (
                del /f "build\maps\mp\gametypes_zm\_score.gsc"
            )
            xcopy /c /f "build\_clientids.gsc" "build\maps\mp\gametypes_zm" /Y
            del /f "build\_clientids.gsc"
        ) else (
            mkdir "build\maps\mp\gametypes_zm"
            if exist "build\maps\mp\gametypes_zm\_clientids.gsc" (
                del /f "build\maps\mp\gametypes_zm\_score.gsc"
            )
            xcopy /c /f "build\_clientids.gsc" "build\maps\mp\gametypes_zm" /Y
            del /f "build\_clientids.gsc"
        )
        echo.
        color 2
        echo - Compiled finished! The output file is in build\maps\mp\gametypes_zm\_clientids.gsc.
        echo.
    ) else (
        echo.
        color 1
        echo - Cannot find resources\compiler\Irony.dll, the compiling process will stop here.
        echo - You can find the uncompiled, merged file in build\final.gsc.
        echo.
    )
) else (
    echo.
    color 1
    echo Cannot find resources\compiler\Compiler.exe, the compiling process will stop here.
    echo You can find the uncompiled, merged file in build\final.gsc.
    echo.
)

pause
color 7