@echo off
set MODNAME=RPQuickSortB42

echo Building %MODNAME%...

if exist build rmdir /S /Q build
mkdir build
xcopy "Contents\mods\%MODNAME%" "build\%MODNAME%\" /S /E /Y
cd "build\%MODNAME%"
if not exist common mkdir common
if not exist 42 mkdir 42
xcopy media 42\media\ /S /E /Y
copy mod.info 42\
copy poster.png 42\

echo Build for %MODNAME% completed. Press any key to exit.
pause
