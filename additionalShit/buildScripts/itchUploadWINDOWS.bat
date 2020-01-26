@echo off
color 0e
cd ..
cd ..
@echo on
lime build windows -release
butler push ./export/release/windows/bin ninja-muffin24/pixel-day-2020:windows
butler status ninja-muffin24/pixel-day-2020:windows
pause