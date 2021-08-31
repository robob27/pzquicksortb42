@echo off

echo This script contains destructive commands. Press any key to continue or Ctrl-C to abort.
pause

set MODNAME=RPQuickSortB42
echo Building %MODNAME%...

if exist build rmdir /S /Q build
mkdir build
xcopy "Contents\mods\%MODNAME%" "build\%MODNAME%\" /S /E /Y
cd "build\%MODNAME%"
REM Currently the common folder is left empty
if not exist common mkdir common
REM I guess we have to copy media/mod.info/poster into the 42 folder. Copy - not move. This is the whole reason this script exists now.
if not exist 42 mkdir 42
xcopy media 42\media\ /S /E /Y
copy mod.info 42\
copy poster.png 42\

REM Now we need to update create the common/42 folders inside Contents/mods/%MODNAME%
cd ../..
if exist "Contents\mods\%MODNAME%\common" rmdir /S /Q "Contents\mods\%MODNAME%\common
if exist "Contents\mods\%MODNAME%\42" rmdir /S /Q "Contents\mods\%MODNAME%\42"
if not exist "Contents\mods\%MODNAME%\common" mkdir "Contents\mods\%MODNAME%\common"
if not exist "Contents\mods\%MODNAME%\42" mkdir "Contents\mods\%MODNAME%\42"
xcopy "build\%MODNAME%\common" "Contents\mods\%MODNAME%\common" /S /E /Y
xcopy "build\%MODNAME%\42" "Contents\mods\%MODNAME%\42" /S /E /Y

cd ../..
if exist "mods\%MODNAME%" rmdir /S /Q "mods\%MODNAME%"
xcopy "Workshop\%MODNAME%\build\%MODNAME%" "mods\%MODNAME%\" /S /E /Y

echo Build for %MODNAME% completed. Press any key to exit.
pause
